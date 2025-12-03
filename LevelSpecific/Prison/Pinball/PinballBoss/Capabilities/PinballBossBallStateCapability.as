struct FPinballBossBallStateActivateParams
{
	FVector SpawnLocation;
};

class UPinballBossBallStateCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::Gameplay;

	APinballBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APinballBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPinballBossBallStateActivateParams& Params) const
	{
		if(Boss.BossState != EPinballBossState::Ball)
			return false;

		FVector SpawnLocation = Boss.GetBallSocketLocation();

		if(SceneView::IsFullScreen())
		{
			FVector2D ScreenPosition;
			SceneView::ProjectWorldToScreenPosition(SceneView::FullScreenPlayer, SpawnLocation, ScreenPosition);

			FVector ViewLocation;
			FVector ViewDirection;
			SceneView::DeprojectScreenToWorld_Absolute(ScreenPosition, ViewLocation, ViewDirection);

			const FPlane GameplayPlane = FPlane(FVector(0, SpawnLocation.Y, SpawnLocation.Z), FVector::ForwardVector);
			SpawnLocation = Math::RayPlaneIntersection(ViewLocation, ViewDirection, GameplayPlane);
		}

		Params.SpawnLocation = SpawnLocation;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.BossState != EPinballBossState::Ball)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPinballBossBallStateActivateParams Params)
	{
		Boss.SetBossState(EPinballBossState::Ball);

		HideBallOnBoss();
		SpawnBossBall(Params.SpawnLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ShowBallOnBoss();
		DestroyBossBall();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FRotator Rotation = Math::RInterpTo(Boss.ActorRotation,FRotator::MakeFromX(FVector::BackwardVector), DeltaTime, 1);
		Boss.SetActorRotation(Rotation);

		if(!Boss.bBallRotationControlledFromBP)
		{
			const FRotator BallRelativeRotation = Math::RInterpTo(Boss.BallLookAtComp.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 2);
			Boss.BallLookAtComp.SetRelativeRotation(BallRelativeRotation);
		}
	}

	private void HideBallOnBoss()
	{
		Boss.BallMeshComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	private void ShowBallOnBoss()
	{
		Boss.BallMeshComp.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
	}

	private void SpawnBossBall(FVector SpawnLocation)
	{
		if(IsValid(Boss.BallForm))
		{
			Boss.BallForm.RemoveActorDisable(this);
			Boss.BallForm.TeleportActor(SpawnLocation, FRotator::MakeFromX(FVector::BackwardVector), this);
		}
		else
		{
			Boss.BallForm = SpawnActor(Boss.BallFormClass, SpawnLocation, FRotator::MakeFromX(FVector::BackwardVector), bDeferredSpawn = true);
			Boss.BallForm.MakeNetworked(Boss, n"BallForm");
			Boss.BallForm.SetActorControlSide(Boss);
			FinishSpawningActor(Boss.BallForm);
		}

		Boss.BallForm.OnSpawned(
			Boss,
			Boss.BP_GetPhase(),
			Boss.GetBallSocketTransform()
		);

		UPinballBossEventHandler::Trigger_OnKnockedOut(Boss);
		UPinballBossBallEventHandler::Trigger_OnKnockedOut(Boss.BallForm);
	}

	private void DestroyBossBall()
	{
		UPinballBossEventHandler::Trigger_OnBallReturn(Boss);
		Boss.BallForm.AddActorDisable(this);
	}
};