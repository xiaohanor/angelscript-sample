class UPrisonBossLookAtPlayerCapability : UPrisonBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer = Boss.GetDistanceTo(Game::Mio) > Boss.GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;

		FVector DirToPlayer = (ClosestPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 3.0);
		Boss.SetActorRotation(Rot);
	}
}