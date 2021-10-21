using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DotGrapher : MonoBehaviour
{
    public GameObject dot;
    public PyramidHandler pHandler;
    public MGrapher mGrapher;

    public float EvaluateHyperplane(Vector2 pt, Hyperplane hyp)
    {
        return (float) ((pt.x*hyp.coeff[0] + pt.y*hyp.coeff[1] + hyp.coeff[3])/-hyp.coeff[2]);
    }

    public void GraphHyperplane(Hyperplane hyp, float[] xBounds, float[] yBounds, float dotScale, int density, Color col)
    {
        GameObject hyperplane = new GameObject();
        hyperplane.name = "Hyperplane";
        for(int i = 0; i < density; i++)
        {
            Vector3 pt = new Vector3(Random.Range(xBounds[0], xBounds[1]), Random.Range(yBounds[0], yBounds[1]), 0f);
            pt.z = EvaluateHyperplane(new Vector2(pt.x, pt.y), hyp);
            GameObject g = Instantiate(dot, pt, Quaternion.identity);
            g.transform.localScale = Vector3.one * dotScale;

            var dotRenderer = g.GetComponent<Renderer>();
            dotRenderer.material.SetColor("_Color", col);

            g.transform.parent = hyperplane.transform;
        }
    }

    public void GraphPoint(Vector3 v, float dotScale, Color col)
    {
        GameObject pt = new GameObject();
        pt.name = "Point";
        GameObject g = Instantiate(dot, v, Quaternion.identity);
        g.transform.localScale = Vector3.one * dotScale;

        var dotRenderer = g.GetComponent<Renderer>();
        dotRenderer.material.SetColor("_Color", col);

        g.transform.parent = pt.transform;
    }
}
