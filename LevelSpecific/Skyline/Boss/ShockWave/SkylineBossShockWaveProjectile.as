class ASkylineBossShockWaveProjectile : ASkylineBossProjectile
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		Move(Velocity * DeltaSeconds);
	}
}