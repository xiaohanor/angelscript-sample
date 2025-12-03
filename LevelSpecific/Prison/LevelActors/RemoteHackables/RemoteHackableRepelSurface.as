class ARemoteHackableRepelSurface : AMagneticFieldRepelSurface
{
	UPROPERTY(DefaultComponent, Attach = SurfaceRoot)
	URemoteHackingResponseComponent HackingComp;

	UPROPERTY(DefaultComponent)
	URemoteHackingResponseAudioComponent HackingAudioComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableRepelSurfaceCapability");

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedOffset;
	default SyncedOffset.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(EditAnywhere)
	float MinOffset = -1400.0;
	UPROPERTY(EditAnywhere)
	float MaxOffset = 1400.0;

	UPROPERTY(BlueprintReadOnly)
	float TranslationAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SurfaceRoot.SetRelativeLocation(FVector(0.0, SyncedOffset.Value, 0.0));

		TranslationAlpha = Math::GetMappedRangeValueClamped(FVector2D(MinOffset, MaxOffset), FVector2D(0.0, 1.0), SyncedOffset.Value);
	}
}

class URemoteHackableRepelSurfaceCapability : URemoteHackableBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ARemoteHackableRepelSurface RepelSurface;

	float MoveSpeed = 400.0;
	float CurSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		RepelSurface = Cast<ARemoteHackableRepelSurface>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		RepelSurface.SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		RepelSurface.SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::Low);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if(HasControl())
		{
			const float HorizontalInputRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw).Y;

			const FVector Input = PlayerMoveComp.MovementInput;
			const float HorizontalInputWorld = Input.DotProduct(RepelSurface.SurfaceRoot.RightVector);

			// Combine both world space input and local input to allow for either simply pressing left/right, or pressing in the travel direction (which can be up or down, if the camera is rotated)
			const float HorizontalInput = Math::Clamp(HorizontalInputWorld + HorizontalInputRaw, -1, 1);

			CurSpeed = Math::FInterpTo(CurSpeed, HorizontalInput * MoveSpeed, DeltaTime, 4.0);
			// Elevator.CurrentHeight = Math::Clamp(Elevator.CurrentHeight + (Input.X * Elevator.MoveSpeed * DeltaTime), 0.0, Elevator.MaxHeight);
			const float CurrentOffset = RepelSurface.SyncedOffset.Value;
			const float NewOffset = Math::Clamp(CurrentOffset + (CurSpeed * DeltaTime), RepelSurface.MinOffset, RepelSurface.MaxOffset);
			RepelSurface.SyncedOffset.SetValue(NewOffset);

			if (HorizontalInput != 0.0 && CurrentOffset != NewOffset)
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(ActiveDuration * 30) * 0.2;
				FF.RightMotor = Math::Sin(-ActiveDuration * 30) * 0.2;
				Player.SetFrameForceFeedback(FF);
			}
		}
	}
}