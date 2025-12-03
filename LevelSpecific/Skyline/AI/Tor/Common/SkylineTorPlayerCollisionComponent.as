class USkylineTorPlayerCollisionComponent : UActorComponent
{
	bool bEnabled;

	void DisableCollision()
	{
		bEnabled = false;
	}

	void EnableCollision()
	{
		bEnabled = true;
	}
}