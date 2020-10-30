using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
[RequireComponent(typeof(Camera))]

public class SSAO : MonoBehaviour
{
    public Material mat;

    // Start is called before the first frame update
    void Start()
    {
        var cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.DepthNormals;

        var shader = Shader.Find("Hidden/SSAO");
        if(mat == null)
            mat = new Material(shader);
        mat.hideFlags = HideFlags.DontSave;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        mat.SetTexture("_MainTex", source);
        
        Graphics.Blit(source, destination, mat);
    }

    //private void OnDestroy()
    //{
    //    GameObject.Destroy(mat);
    //    mat = null;
    //}
}
