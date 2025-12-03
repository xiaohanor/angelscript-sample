class UIslandOverseerReturnGrenadePlayerComponent : UActorComponent
{
	bool bReturnRight;
	bool bReturnLeft;
	bool bThrow;

	void Throw()
	{
		bThrow = true;
	}
}