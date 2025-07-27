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
    Material material;

    void Start() => Initialize();

    void Update()
    {
        EnsureResourcesCreated();
        if (triangleMesh != null && material != null)
            Graphics.DrawMesh(triangleMesh, transform.localToWorldMatrix, material, 0);
    }

    void OnEnable()
    {
        EnsureResourcesCreated();
        UpdateColors();
    }

    void OnValidate()
    {
        if (material != null)
            UpdateColors();
    }

    void OnDisable() => CleanupResources();
    void OnDestroy() => CleanupResources();

    void Initialize()
    {
        CreateTriangleMesh();
        CreateMaterial();
        UpdateColors();
    }

    void EnsureResourcesCreated()
    {
        if (triangleMesh == null)
            CreateTriangleMesh();
        if (material == null)
            CreateMaterial();
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

    void CreateMaterial()
    {
        var shader = Shader.Find("Custom/SpectralTriangle");
        if (shader == null)
        {
            Debug.LogError("Shader 'Custom/SpectralTriangle' not found!");
            return;
        }

        material = new Material(shader);
    }

    void UpdateColors()
    {
        if (material == null) return;

        material.SetColor("_ColorA", colorA);
        material.SetColor("_ColorB", colorB);
        material.SetColor("_ColorC", colorC);
    }

    void CleanupResources()
    {
        if (triangleMesh != null)
        {
            DestroyResource(triangleMesh);
            triangleMesh = null;
        }
            
        if (material != null)
        {
            DestroyResource(material);
            material = null;
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