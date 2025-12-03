
/** 
 * death effect + Velocity available + camera flows a bit along the direction.
 */

class UDeathEffect_Moving : UDeathEffect
{
	default bResetMovement = false;

	UPlayerHealthComponent HealthComp;
	UPlayerMovementComponent MoveComp;

	bool bDied = false;
	bool bFinishedDying = false;
	bool bRespawned = false;
	bool bRemoved = false;

	UPROPERTY()
	FVector DeathVelocity = FVector::ZeroVector;
	FVector CameraVelocity;

	ADeathStaticCamera StaticCamera;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		HealthComp = UPlayerHealthComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Super::OnRemoved();
		
		if(IsValid(Player))
		{
			// Clear any offsets we applied on the player (just in case)
			Player.CameraOffsetComponent.ClearOffset(this);
			Player.MeshOffsetComponent.ClearOffset(this);

			// Clear the camera applied on the player (just in case)
			if (StaticCamera != nullptr)
				DespawnDeathCamera();
			Player.DeactivateCameraByInstigator(this);
		}

		bRemoved = true;
	}

	UFUNCTION(BlueprintOverride)
	void Died()
	{
		bDied = true;
		Player.CameraOffsetComponent.SnapToLocation(this, Player.CameraOffsetComponent.WorldLocation);
		Player.MeshOffsetComponent.SnapToLocation(this, Player.MeshOffsetComponent.WorldLocation);

		DeathImpulse = MoveComp.GetPendingImpulse();
		CameraVelocity = Player.ActorVelocity.GetSafeNormal() * Player.ViewVelocity.GetClampedToMaxSize(1000.0).Size();
		DeathVelocity = CameraVelocity + DeathImpulse;

		SpawnDeathCamera();
	}

	void SpawnDeathCamera()
	{
		if (SceneView::IsFullScreen())
			return;
		
		if (!bUseDeathCamera)
			return;

		if (StaticCamera != nullptr)
		{
			DespawnDeathCamera();
		}

		StaticCamera = ADeathStaticCamera::Spawn(
			Player.ViewLocation, Player.ViewRotation, bDeferredSpawn = true
		);
		
		if (bStaticCameraDeath)
		{
			StaticCamera.StopDuration = 0.0;
		}
		else
		{
			if (DeathDamageParams.CameraStopDuration >= 0.0)
				StaticCamera.StopDuration = DeathDamageParams.CameraStopDuration;
			else
				StaticCamera.StopDuration = UDeathRespawnEffectSettings::GetSettings(Player).DefaultCameraStopDuration;
		}
		
		StaticCamera.BlendOutDuration = UDeathRespawnEffectSettings::GetSettings(Player).DefaultCameraBlendOutDuration;
		StaticCamera.CameraStartingVelocity = Player.ActorVelocity;
		StaticCamera.Player = Player;
		FinishSpawningActor(StaticCamera);

		Player.ActivateCamera(StaticCamera, 0.0, this, EHazeCameraPriority::Default);
		StaticCamera.Camera.SetFieldOfView(Player.ViewFOV);
	}

	UFUNCTION(BlueprintOverride)
	void FinishedDying()
	{
		Super::FinishedDying();
		bFinishedDying = true;
	}

	UFUNCTION(BlueprintOverride)
	void RespawnTriggered()
	{
		Super::RespawnTriggered();
		Player.CameraOffsetComponent.ClearOffset(this);
		Player.MeshOffsetComponent.ClearOffset(this);
		bRespawned = true;

		if (StaticCamera != nullptr)
		{
			DespawnDeathCamera();
		}
	}

	void DespawnDeathCamera()
	{
		Player.DeactivateCamera(StaticCamera, StaticCamera.BlendOutDuration);
		Player.ClearCameraSettingsByInstigator(this, StaticCamera.BlendOutDuration);
		StaticCamera.DestroyActor();
		StaticCamera = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bDied)
			return;
		if (bFinishedDying)
			return;
		if (bRespawned)
			return;
		if (bRemoved)
			return;

		// PrintToScreenScaled("Vel: " + DeathVelocity);
		// PrintToScreenScaled("Speed: " + DeathVelocity.Size());
		Player.CameraOffsetComponent.SnapToLocation(this, Player.CameraOffsetComponent.WorldLocation + CameraVelocity*DeltaTime + DeathImpulse*DeltaTime);
		Player.MeshOffsetComponent.SnapToLocation(this, Player.MeshOffsetComponent.WorldLocation + CameraVelocity*DeltaTime + DeathImpulse*DeltaTime);
		
		// push the velocity down to zero by applying friction
		DeathVelocity *= Math::Pow(Math::Exp(-5.0), DeltaTime);
		CameraVelocity *= Math::Pow(Math::Exp(-5.0), DeltaTime);

		if (!DeathImpulse.IsNearlyZero())
		{
			DeathImpulse *= Math::Pow(Math::Exp(-2.0), DeltaTime);
			DeathImpulse += MoveComp.Gravity * DeltaTime;
		}
	}

}