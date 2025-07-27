using UnityEngine;

[ExecuteInEditMode]
public class SpectralTriangleSample : MonoBehaviour
{
    [Header("Triangle Colors")]
    [ColorUsage(false)]
    public Color colorA = Color.red;

    [ColorUsage(false)]
    public Color colorB = Color.green;

    [ColorUsage(false)]
    public Color colorC = Color.blue;

    Mesh triangleMesh;
    Material spectralMaterial;
    Material linearMaterial;

    void Start() => Initialize();

    void Update()
    {
        EnsureResourcesCreated();
        if (triangleMesh != null && spectralMaterial != null && linearMaterial != null)
        {
            var leftMatrix = transform.localToWorldMatrix * Matrix4x4.Translate(Vector3.left * 0.6f);
            var rightMatrix = transform.localToWorldMatrix * Matrix4x4.Translate(Vector3.right * 0.6f);

            Graphics.DrawMesh(triangleMesh, leftMatrix, spectralMaterial, 0);
            Graphics.DrawMesh(triangleMesh, rightMatrix, linearMaterial, 0);
        }
    }

    void OnEnable()
    {
        EnsureResourcesCreated();
        UpdateColors();
    }

    void OnValidate()
    {
        if (spectralMaterial != null && linearMaterial != null)
            UpdateColors();
    }

    void OnDisable() => CleanupResources();
    void OnDestroy() => CleanupResources();

    void Initialize()
    {
        CreateTriangleMesh();
        CreateMaterials();
        UpdateColors();
    }

    void EnsureResourcesCreated()
    {
        if (triangleMesh == null)
            CreateTriangleMesh();
        if (spectralMaterial == null || linearMaterial == null)
            CreateMaterials();
    }

    void CreateTriangleMesh()
    {
        triangleMesh = new Mesh { name = "Spectral Triangle" };

        var vertices = new Vector3[]
        {
            new Vector3(0f, 0.577f, 0f),
            new Vector3(-0.5f, -0.289f, 0f),
            new Vector3(0.5f, -0.289f, 0f)
        };

        var uvs = new Vector2[]
        {
            new Vector2(0.5f, 1f),
            new Vector2(0f, 0f),
            new Vector2(1f, 0f)
        };

        var triangles = new int[] { 0, 1, 2 };

        triangleMesh.vertices = vertices;
        triangleMesh.uv = uvs;
        triangleMesh.triangles = triangles;
        triangleMesh.RecalculateNormals();
    }

    void CreateMaterials()
    {
        var shader = Shader.Find("Custom/SpectralTriangle");
        if (shader == null)
        {
            Debug.LogError("Shader 'Custom/SpectralTriangle' not found!");
            return;
        }

        spectralMaterial = new Material(shader);
        linearMaterial = new Material(shader);
    }

    void UpdateColors()
    {
        if (spectralMaterial == null || linearMaterial == null) return;

        SetMaterialColors(spectralMaterial, 1.0f);
        SetMaterialColors(linearMaterial, 0.0f);
    }

    void SetMaterialColors(Material material, float useSpectralMix)
    {
        material.SetColor("_ColorA", colorA);
        material.SetColor("_ColorB", colorB);
        material.SetColor("_ColorC", colorC);
        material.SetFloat("_UseSpectralMix", useSpectralMix);
    }

    void CleanupResources()
    {
        if (triangleMesh != null)
        {
            DestroyResource(triangleMesh);
            triangleMesh = null;
        }

        if (spectralMaterial != null)
        {
            DestroyResource(spectralMaterial);
            spectralMaterial = null;
        }

        if (linearMaterial != null)
        {
            DestroyResource(linearMaterial);
            linearMaterial = null;
        }
    }

    void DestroyResource(Object resource)
    {
        if (Application.isPlaying)
            Destroy(resource);
        else
            DestroyImmediate(resource);
    }
}