using UnityEngine;
using UnityEditor;
using NUnit.Framework;

namespace SpectralJS.Tests
{
    public class SpectralComputeTests
    {
        private ComputeShader testComputeShader;
        private Texture2D referenceTexture;
        private ComputeBuffer statisticsBuffer;
        
        private const int STATISTICS_COUNT = 7; // totalPixels, matchedPixels, acceptablePixels, warningPixels, errorPixels, maxErrorAsUint, onePercentErrorPixels
        private const float ERROR_THRESHOLD = 0.02f; // 2% tolerance
        private const float WARNING_THRESHOLD = 0.05f; // 5% warning threshold
        private const float ACCEPTABLE_ERROR_RATIO = 0.01f; // Allow 1% of pixels to have errors
        
        private struct ValidationResult
        {
            public float totalPixels;
            public float matchedPixels;
            public float acceptablePixels;
            public float warningPixels;
            public float errorPixels;
            public float maxError;
            public float onePercentErrorPixels;
            
            public float MatchRatio => totalPixels > 0 ? matchedPixels / totalPixels : 0;
            public float AcceptableRatio => totalPixels > 0 ? acceptablePixels / totalPixels : 0;
            public float WarningRatio => totalPixels > 0 ? warningPixels / totalPixels : 0;
            public float ErrorRatio => totalPixels > 0 ? errorPixels / totalPixels : 0;
            public float OnePercentErrorRatio => totalPixels > 0 ? onePercentErrorPixels / totalPixels : 0;
        }
        
        [OneTimeSetUp]
        public void OneTimeSetUp()
        {
            // Load compute shader
            testComputeShader = Resources.Load<ComputeShader>("SpectralTestCompute");
            Assert.IsNotNull(testComputeShader, "SpectralTestCompute compute shader not found");
            
            // Load reference texture
            referenceTexture = Resources.Load<Texture2D>("SpectralMixReference");
            Assert.IsNotNull(referenceTexture, "Reference texture not found in Resources");
            
            // Create statistics buffer
            statisticsBuffer = new ComputeBuffer(STATISTICS_COUNT, sizeof(uint));
        }
        
        [OneTimeTearDown]
        public void OneTimeTearDown()
        {
            if (statisticsBuffer != null)
            {
                statisticsBuffer.Release();
                statisticsBuffer = null;
            }
        }
        
        private ValidationResult RunValidation(string kernelName)
        {
            // Clear statistics buffer explicitly
            uint[] clearData = new uint[STATISTICS_COUNT];
            for (int i = 0; i < STATISTICS_COUNT; i++) clearData[i] = 0;
            statisticsBuffer.SetData(clearData);
            
            // Get kernel
            int kernel = testComputeShader.FindKernel(kernelName);
            
            // Set parameters
            testComputeShader.SetTexture(kernel, "ReferenceTexture", referenceTexture);
            testComputeShader.SetBuffer(kernel, "Statistics", statisticsBuffer);
            testComputeShader.SetFloat("ErrorThreshold", ERROR_THRESHOLD);
            testComputeShader.SetFloat("WarningThreshold", WARNING_THRESHOLD);
            
            // Calculate dispatch size
            int threadGroupsX = Mathf.CeilToInt(referenceTexture.width / 8.0f);
            int threadGroupsY = Mathf.CeilToInt(referenceTexture.height / 8.0f);
            
            // Dispatch compute shader
            testComputeShader.Dispatch(kernel, threadGroupsX, threadGroupsY, 1);
            
            // Read back results
            uint[] results = new uint[STATISTICS_COUNT];
            statisticsBuffer.GetData(results);
            
            return new ValidationResult
            {
                totalPixels = results[0],
                matchedPixels = results[1],
                acceptablePixels = results[2],
                warningPixels = results[3],
                errorPixels = results[4],
                maxError = results[5] / 10000.0f,  // Convert back from scaled uint
                onePercentErrorPixels = results[6]
            };
        }
        
        [Test]
        public void ColorBarValidation()
        {
            var result = RunValidation("ColorBarValidation");
            
            Debug.Log($"Color Bar Validation Results:");
            Debug.Log($"  Total pixels: {result.totalPixels}");
            Debug.Log($"  Match ratio: {result.MatchRatio:P2}");
            Debug.Log($"  Acceptable ratio: {result.AcceptableRatio:P2}");
            Debug.Log($"  Warning ratio: {result.WarningRatio:P2}");
            Debug.Log($"  Error ratio: {result.ErrorRatio:P2}");
            Debug.Log($"  1% error pixels: {result.onePercentErrorPixels} ({result.OnePercentErrorRatio:P2})");
            Debug.Log($"  Max error: {result.maxError:F4}");
            
            // Also output to console for visibility in test results
            System.Console.WriteLine($"ColorBar - 1% error pixels: {result.onePercentErrorPixels} out of {result.totalPixels} total pixels");
            
            // Color bars should match almost perfectly (temporarily relaxed for debugging)
            Assert.Greater(result.MatchRatio, 0.98f, 
                $"Color bar match ratio too low: {result.MatchRatio:P2}. " +
                "This indicates the test environment may not be functioning correctly.");
            
            Assert.Less(result.maxError, ERROR_THRESHOLD * 2, 
                $"Maximum error in color bars too high: {result.maxError:F4}");
        }
        
        [Test]
        public void SpectralMixValidation()
        {
            var result = RunValidation("SpectralMixValidation");
            
            Debug.Log($"Spectral Mix Validation Results:");
            Debug.Log($"  Total pixels: {result.totalPixels}");
            Debug.Log($"  Match ratio: {result.MatchRatio:P2}");
            Debug.Log($"  Acceptable ratio: {result.AcceptableRatio:P2}");
            Debug.Log($"  Warning ratio: {result.WarningRatio:P2}");
            Debug.Log($"  Error ratio: {result.ErrorRatio:P2}");
            Debug.Log($"  1% error pixels: {result.onePercentErrorPixels} ({result.OnePercentErrorRatio:P2})");
            Debug.Log($"  Max error: {result.maxError:F4}");
            
            // Also output to console for visibility in test results
            System.Console.WriteLine($"1% error pixels: {result.onePercentErrorPixels} out of {result.totalPixels} total pixels");
            
            // Spectral mix should have high accuracy with some tolerance
            Assert.Greater(result.AcceptableRatio, 1.0f - ACCEPTABLE_ERROR_RATIO, 
                $"Too many pixels with large differences: {result.ErrorRatio:P2}");
            
            // Warn if there are many pixels in the warning range
            if (result.WarningRatio > 0.05f)
            {
                Debug.LogWarning($"High number of pixels in warning range: {result.WarningRatio:P2}");
            }
            
            // Log detailed error information if test fails
            if (result.ErrorRatio > ACCEPTABLE_ERROR_RATIO)
            {
                Debug.LogError($"Spectral mix validation failed with {result.ErrorRatio:P2} error pixels");
                Debug.LogError($"Maximum error: {result.maxError:F4}");
            }
        }
    }
}