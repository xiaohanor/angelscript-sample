class USkylineBallBossDeathCameraCapability : UHazePlayerCapability
{

	USkylineBallBossActorReferenceComponent BallBossRefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	
		BallBossRefsComp = USkylineBallBossActorReferenceComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallBossRefsComp.Refs == nullptr)
			return false;
		if (BallBossRefsComp.Refs.BallBoss.GetPhase() <= ESkylineBallBossPhase::PostChaseElevator)
			return false;
		if (BallBossRefsComp.Refs == nullptr)
			return false;
		if (BallBossRefsComp.Refs.MioDeathCamera == nullptr)
			return false;
		if (BallBossRefsComp.Refs.ZoeDeathCamera == nullptr)
			return false;
		if (!Player.IsPlayerDead())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
		{
			if (GetIsMioInsideBallBoss())
			{
				auto CameraComp = UHazeCameraUserComponent::Get(Game::Mio);
				FTransform MioViewTransform = CameraComp.GetViewTransform();
				BallBossRefsComp.Refs.MioInsideDeathCamera.SetActorTransform(MioViewTransform);
				Player.ActivateCamera(BallBossRefsComp.Refs.MioInsideDeathCamera, 0.0, this, EHazeCameraPriority::VeryHigh);
			}
			else
				Player.ActivateCamera(BallBossRefsComp.Refs.MioDeathCamera, BallBossRefsComp.Refs.DeathCameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
		}
		else
			Player.ActivateCamera(BallBossRefsComp.Refs.ZoeDeathCamera, BallBossRefsComp.Refs.DeathCameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCameraByInstigator(this, 0.0);
		Player.SnapCameraBehindPlayer();
	}

	bool GetIsMioInsideBallBoss()
	{
		if (BallBossRefsComp.Refs.BallBoss.GetPhase() != ESkylineBallBossPhase::TopMioIn && BallBossRefsComp.Refs.BallBoss.GetPhase() != ESkylineBallBossPhase::TopMioInKillWeakpoint)
			return false;
		if (Game::Mio.GetDistanceTo(BallBossRefsComp.Refs.BallBoss) >= BallBossRefsComp.Refs.BallBoss.GetBossRadius() + 200.0)
			return false;
		return true;
	}
};