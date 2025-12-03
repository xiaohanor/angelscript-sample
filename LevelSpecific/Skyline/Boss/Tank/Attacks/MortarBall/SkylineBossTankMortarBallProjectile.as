class ASkylineBossMortarBallProjectile : ASkylineBossProjectile
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		Move(Velocity * DeltaSeconds);
	}
}