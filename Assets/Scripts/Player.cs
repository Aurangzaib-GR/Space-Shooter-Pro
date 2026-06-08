using System.Collections;
using UnityEngine;

public class Player : MonoBehaviour
{
    [SerializeField] private float _speed = 3.5f;
    [SerializeField] private float _fireRate = 0.4f;
    [SerializeField] private int _lives = 3;
    [SerializeField] private bool _isTripleShotActive = false;

    [SerializeField] private GameObject _LaserPrefab;
    [SerializeField] private GameObject _TripleShotPrefab;

    private float _canFire = -1f;
    private SpawnManager _spawnManager;
    void Start()
    {
        transform.position = new Vector3(0, -3.59f, 0);
        _spawnManager = GameObject.Find("Spawn_Manager").GetComponent<SpawnManager>();
 
        if(_spawnManager == null )
        {
            Debug.LogError("The Spawn Manager is Null");
        }

    }
    void Update()
    {
        CalculateMovement();

        if (Input.GetKeyDown(KeyCode.Space) && Time.time > _canFire)
        {
            FireLaser();
        }

        void CalculateMovement()
        {
            float horizontalInput = Input.GetAxis("Horizontal");
            float verticalInput = Input.GetAxis("Vertical");

            Vector3 direction = new Vector3(horizontalInput, verticalInput, 0);
            transform.Translate(direction * _speed * Time.deltaTime);

            if (transform.position.y >= 0)
            {
                transform.position = new Vector3(transform.position.x, 0, 0);
            }
            else if (transform.position.y <= -3.8f)
            {
                transform.position = new Vector3(transform.position.x, -3.8f, 0);
            }
            transform.position = new Vector3(Mathf.Repeat(transform.position.x + 11.2f, 22.4f) - 11.2f, transform.position.y, 0f);
        }
        void FireLaser()
        {

            _canFire = Time.time + _fireRate;

            if (_isTripleShotActive == true)
            {
                Instantiate(_TripleShotPrefab, transform.position, Quaternion.identity);

            }
            else
            {
                Instantiate(_LaserPrefab, transform.position + new Vector3(0, 0.945f, 0), Quaternion.identity);

            }
            Debug.Log("Space Key Pressed");
        }
    } 
    public void Damage()
    {
        _lives--;

        if (_lives < 1)
        {
            _spawnManager.onPlayerDeath();
            GameObject.Find("Canvas").GetComponent<UIManager>().ShowRetryPanel();
            Destroy(this.gameObject);
        }
    }

    public void TripleShotActive()
    {
        _isTripleShotActive = true;
        StartCoroutine(TripleShotPowerDownRoutine());
    }

    IEnumerator TripleShotPowerDownRoutine()
    {
        yield return new WaitForSeconds(5.0f);
        _isTripleShotActive = false;
    }

 }
