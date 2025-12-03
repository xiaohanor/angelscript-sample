class AMeltdownWorldSpinPinhole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeGameplay;

	bool bPlayerWasDead = false;
	FVector DeathLocation;
	float DeathLerpTimer = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();

		auto StaticCamera = Cast<AStaticCameraActor>(Manager.SpinPlayer.CurrentlyUsedCamera.Owner);
		if (StaticCamera != nullptr)
		{
			auto MoveViewPoint = Manager.MovePlayer.GetViewPoint(false);
			float CamDistance = (MoveViewPoint.ViewLocation - Manager.MovePlayer.MeshOffsetComponent.WorldLocation).DotProduct(FVector::ForwardVector);

			FRotator ViewRotation = FRotator::MakeFromX(FVector::ForwardVector);
			FVector ViewLocation = Manager.MovePlayer.MeshOffsetComponent.WorldLocation + FVector(CamDistance, 0, 200);

			// Blend back to the player's camera after death
			if (bPlayerWasDead)
			{
				if (!Manager.MovePlayer.IsPlayerDead())
				{
					DeathLerpTimer = 0.0;
					bPlayerWasDead = false;
				}
			}
			else
			{
				if (Manager.MovePlayer.IsPlayerDead())
				{
					DeathLocation = ViewLocation;
					bPlayerWasDead = true;
				}
			}

			DeathLerpTimer += DeltaSeconds;
			if (DeathLerpTimer < 1.0)
			{
				ViewLocation = Math::Lerp(
					DeathLocation,
					ViewLocation,
					Math::EaseInOut(0, 1, DeathLerpTimer, 2)
				);
			}
			
			SetActorLocationAndRotation(ViewLocation, ViewRotation);

			StaticCamera.SetActorRotation(Manager.WorldSpinRotation * ViewRotation.Quaternion());
		}
	}
};