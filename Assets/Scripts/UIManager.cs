using UnityEngine;
using UnityEngine.SceneManagement;

public class UIManager : MonoBehaviour
{
    public GameObject retryPanel;

    void Start()
    {
        if (retryPanel != null)
        {
            retryPanel.SetActive(false);
        }
    }

    public void ShowRetryPanel()
    {
        if (retryPanel != null)
        {
            retryPanel.SetActive(true);
        }
    }

    public void RestartGame()
    {
        if (retryPanel != null)
        {
            retryPanel.SetActive(false);
        }

        SceneManager.LoadScene(SceneManager.GetActiveScene().name);
    }
}