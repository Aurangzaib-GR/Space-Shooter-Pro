using UnityEngine;

public class Enemy : MonoBehaviour
{
    [SerializeField]
    private float _speed = 4.0f;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {
        //Move down 4 meters per second

        transform.Translate(Vector3.down * _speed * Time.deltaTime);


        //if bottom of screen 
        //respawn at top with a new random x position   

        if (transform.position.y < -5)
        {
            float Randomx = Random.Range(-9.4f, 9.4f);
            transform.position = new Vector3(Randomx, 7, 0);
        }

    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.tag == "Player")
        {
            Player player = other.transform.GetComponent<Player>();
            if (player != null) ;
            {
                player.Damage();
            }

            Destroy(this.gameObject);
        }
        if (other.tag == "Laser")
        {
            Destroy(other.gameObject);
            Destroy(this.gameObject);
        }

    }
}