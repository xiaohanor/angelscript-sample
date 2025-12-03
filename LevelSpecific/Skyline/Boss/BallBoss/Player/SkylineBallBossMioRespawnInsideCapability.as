// prevent mio from accidentally triggering nearby respawn volumes when she's inside the boss
class USkylineBallBossMioRespawnInsideCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ASkylineBallBoss BallBoss;
	UPlayerRespawnComponent RespawnComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TListedActors<ASkylineBallBoss> BallBosses;
		BallBoss = BallBosses.Single;
		RespawnComponent = UPlayerRespawnComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBoss.InsideRespawnPoint == nullptr)
			return false;

		if (!BallBoss.bInsideActivated)
			return false;

		if (!IsInInsidePhase())
			return false;

		return true;
	}

	bool IsInInsidePhase() const
	{
		if (BallBoss.GetPhase() < ESkylineBallBossPhase::TopMioIn)
			return false;
		if (BallBoss.GetPhase() > ESkylineBallBossPhase::TopDeath)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsInInsidePhase())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FOnRespawnOverride Delegate;
		Delegate.BindUFunction(this, n"GetInsideRespawnLocation");
		RespawnComponent.ApplyRespawnOverrideDelegate(this, Delegate, EInstigatePriority::High);
	}

	UFUNCTION()
	private bool GetInsideRespawnLocation(AHazePlayerCharacter RespawnPlayer, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnPoint = BallBoss.InsideRespawnPoint;
		OutLocation.RespawnRelativeTo = BallBoss.InsideRespawnPoint.RootComponent;
		OutLocation.RespawnTransform = BallBoss.InsideRespawnPoint.GetRelativePositionForPlayer(Player);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnComponent.ClearRespawnOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DevTogglesPlayerHealth::DrawRespawnPoint.IsEnabled(Player))
		{
			Debug::DrawDebugCapsule(BallBoss.InsideRespawnPoint.ActorCenterLocation, Player.CapsuleComponent.CapsuleHalfHeight, Player.CapsuleComponent.CapsuleRadius, BallBoss.InsideRespawnPoint.ActorRotation, Player.GetPlayerUIColor(), Thickness = 16.0, bDrawInForeground = true);
			Debug::DrawDebugString(BallBoss.InsideRespawnPoint.ActorCenterLocation, "" + BallBoss.InsideRespawnPoint.ActorNameOrLabel);
		}
	}
};