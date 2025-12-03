#if !RELEASE
namespace DevTogglePinball
{
	const FHazeDevToggleBool DrawRisingDeathVolume;
};
#endif

UCLASS(Abstract)
class APinballBoss_RisingDeathVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDeathVolumeComponent DeathVolumeComp;

	UPROPERTY(DefaultComponent)
	UPinballGlobalResetComponent GlobalResetComp;

	UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float DistanceBelowPlayer = 3000;

	bool bIsMoving = false;
	FVector InitialRelativeLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Pinball::GetBallPlayer());

		InitialRelativeLocation = DeathVolumeComp.RelativeLocation;

		GlobalResetComp.PreActivateProgressPoint.AddUFunction(this, n"PreActivateProgressPoint");
		DeathVolumeComp.DisableTrigger(this);

#if !RELEASE
		DevTogglePinball::DrawRisingDeathVolume.MakeVisible();
#endif
	}

	UFUNCTION()
	private void PreActivateProgressPoint()
	{
		DeathVolumeComp.SetRelativeLocation(InitialRelativeLocation);
		bIsMoving = false;
		DeathVolumeComp.DisableTrigger(this);
	}

	UFUNCTION(BlueprintCallable)
	void Enable(bool bStartMoving = true)
	{
		Move(true);
		DeathVolumeComp.EnableTrigger(this);

		if(bStartMoving)
			StartMoving();
	}

	UFUNCTION(BlueprintCallable)
	void StartMoving()
	{
		bIsMoving = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Move(bIsMoving);

#if EDITOR
		if(DevTogglePinball::DrawRisingDeathVolume.IsEnabled())
		{
			PrintToScreen(f"Rising Death Volume Height: {DeathVolumeComp.RelativeLocation.Z}");
			Debug::DrawDebugBox(DeathVolumeComp.WorldLocation, DeathVolumeComp.Shape.BoxExtents * DeathVolumeComp.WorldScale, DeathVolumeComp.WorldRotation, FLinearColor::Red, 10);
		}
#endif
	}

	void Move(bool bFollowHeight)
	{
		float Height = DeathVolumeComp.RelativeLocation.Z;
		FVector PlayerPosition = Drone::GetMagnetDronePlayer().GetActorLocation();
		FVector PlayerRelativePosition = ActorTransform.InverseTransformPositionNoScale(PlayerPosition);

		if(bFollowHeight)
		{
			Height = Math::Max(PlayerRelativePosition.Z - DistanceBelowPlayer, Height);
		}

		DeathVolumeComp.SetRelativeLocation(FVector(PlayerRelativePosition.X, PlayerRelativePosition.Y, Height));
	}
};
