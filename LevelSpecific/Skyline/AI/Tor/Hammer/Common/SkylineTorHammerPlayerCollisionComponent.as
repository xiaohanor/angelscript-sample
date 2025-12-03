class USkylineTorHammerPlayerCollisionComponent : UActorComponent
{
	private bool _bEnabled;
	
	bool GetbEnabled() property
	{
		return _bEnabled;
	}

	void DisableCollision()
	{
		_bEnabled = false;
	}

	void EnableCollision()
	{
		_bEnabled = true;
	}
}