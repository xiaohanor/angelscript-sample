UCLASS(hideCategories = "InternalHiddenObjects")
class ASkylineFlyingCar2D : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent WorldCollision;
	default WorldCollision.CapsuleHalfHeight = 220.0;
	default WorldCollision.CapsuleRadius = 80.0;
	default WorldCollision.SetCollisionProfileName(n"BlockAllDynamic");
	default WorldCollision.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	USceneComponent VisualRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineFlyingCar2DFocusCamera Camera;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkylineFlyingCar2DFocusCamera CameraTopDown;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SkylineFlyingCar2DMovementCapability");

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestCapabilityOnPlayerComponent;

	UPROPERTY(EditAnywhere)
	float Acceleration = 2000.0;

	UPROPERTY(EditAnywhere)
	float Drag = 2.0;

	UPROPERTY(EditAnywhere)
	EHazePlayer Pilot = EHazePlayer::Zoe;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	AActor TopDownStartLocation;

	FVector2D Input;

	FVector AngularVelocity;
	float AngularDrag = 4.0;

	bool bTopDown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartFlyingCar2D();
	}

	UFUNCTION()
	void EnableTopDown()
	{
		bTopDown = true;

		auto Player = Game::GetPlayer(Pilot);
		Player.ActivateCamera(CameraTopDown, 3.0, this);
		SetActorLocation(TopDownStartLocation.ActorLocation);
		Player.OtherPlayer.UnlockPlayerMovementFromSpline(this);
		Player.OtherPlayer.ClearAiming2DConstraint(this);
	}

	void StartFlyingCar2D()
	{
		auto Player = Game::GetPlayer(Pilot);
		RequestCapabilityOnPlayerComponent.StartInitialSheetsAndCapabilities(Player, this);
		auto PilotComponent = USkylineFlyingCar2DPilotComponent::Get(Player);
		PilotComponent.FlyingCar2D = this;
	
		Player.OtherPlayer.TeleportActor(ActorLocation + ActorUpVector * 100.0, ActorRotation, this);
		Player.OtherPlayer.LockPlayerMovementToSpline(SplineActor, this);
		Player.OtherPlayer.ApplyAiming2DPlaneConstraint(ActorRightVector, this);
	}
}

class USkylineFlyingCar2DFocusCamera : UFocusTargetCamera
{
	UCameraWeightedTargetComponent FocusTargets;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FocusTargets = UCameraWeightedTargetComponent::Get(Owner);
	}

	
	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData,
							   FHazeCameraTransform CameraTransform) const
	{
		auto KeepInViewData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& ActiveKeepInViewSettings = KeepInViewData.UpdaterSettings;
		ActiveKeepInViewSettings.Init(HazeUser);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			auto EditorFocusTargets = UCameraWeightedTargetComponent::Get(Owner);
			KeepInViewData.FocusTargets = EditorFocusTargets.GetEditorPreviewTargets();
			KeepInViewData.PrimaryTargets = EditorFocusTargets.GetEditorPreviewPrimaryTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				KeepInViewData.FocusTargets = FocusTargets.GetFocusTargets(PlayerOwner);
				KeepInViewData.PrimaryTargets = FocusTargets.GetPrimaryTargetsOnly(PlayerOwner);
			}
		}

		KeepInViewData.UseFocusLocation();	
	}
}