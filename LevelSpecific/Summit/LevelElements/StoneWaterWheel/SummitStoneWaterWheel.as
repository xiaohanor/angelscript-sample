asset SummitStoneWaterWheelGravitySettings of UMovementGravitySettings
{
	GravityAmount = 7000;
}

class USummitStoneWaterWheelComponent : USceneComponent
{

}

class ASummitStoneWaterWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USummitStoneWaterWheelComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent WheelMesh;
	default WheelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComp;
	default CapsuleComp.CapsuleRadius = 1650.0;
	default CapsuleComp.CollisionProfileName = n"IgnorePlayerCharacter";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneWaterWheelMoveCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneWaterWheelSplineFollowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitStoneWaterWheelKillPlayerInWayCapability");

	UPROPERTY(DefaultComponent)
	UPlayerInheritMovementComponent PlayerInheritMovementComp;

	UPROPERTY(DefaultComponent)
	USummitNonRollKnockBackComponent NonRollKnockbackComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent ActorSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncRotationComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	USplineLockComponent SplineLockComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerCheckRadius = 1400.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerWeightValue = 350.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float DecelerationValue = 0.4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float SlopeAcceleration = 0.01;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ConstantDeceleration = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxSpeed = 3000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartDisabled = true;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> LandingCameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UForceFeedbackEffect ImpactRumble;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> ActorsToIgnoreMovement;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<TSoftObjectPtr<AActor>> SoftReferencedActorsToIgnoreMovement;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASplineActor FollowSplineActor;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ANightQueenMetal MetalToActivateByMelting;

	UPROPERTY(EditInstanceOnly, Category = "Audio")
	AActorTrigger CliffCrashAudioTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActorTrigger RemoveCollisionTrigger;

	bool bIsActive = true;

	private AHazePlayerCharacter Zoe;
	bool bFollowExitSpline = false;
	private bool bHasActivatedSheet = false;
	bool bHasRemovedCollisionWithPlayers = false;
	private bool bHasRemovedCollisionWithSoftReferencedObjects = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(SummitStoneWaterWheelGravitySettings);

		Zoe = Game::GetZoe();
		SetActorControlSide(Zoe);

		if(bStartDisabled)
			bIsActive = false;

		if(MetalToActivateByMelting != nullptr)
			MetalToActivateByMelting.OnNightQueenMetalMelted.AddUFunction(this, n"OnActivationMetalMelted");

		MoveComp.AddMovementIgnoresActors(this, ActorsToIgnoreMovement);
		FPlayerMovementSplineLockProperties SplineLockProperties;
		SplineLockProperties.LockType = EPlayerSplineLockPlaneType::SplinePlane;
		SplineLockProperties.KeepDeltaSize = ESplineLockKeepDeltaSize::DontKeepDeltaSize;
		LockMovementToSpline(FollowSplineActor, this, EInstigatePriority::Normal, SplineLockProperties);

		RemoveCollisionTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnRemoveCollisionTriggerEntered");
	}

	UFUNCTION()
	private void OnRemoveCollisionTriggerEntered(AActor OverlappedActor, AActor OtherActor)
	{
		if(bHasRemovedCollisionWithPlayers)
			return;
		for(auto Player : Game::Players)
		{
			// MoveComp.AddMovementIgnoresActor(this, Player);
			auto PlayerMoveComp = UPlayerMovementComponent::Get(Player);
			PlayerMoveComp.AddMovementIgnoresActor(this, this);
			bHasRemovedCollisionWithPlayers = true;
		}
	}

	UFUNCTION()
	private void OnActivationMetalMelted()
	{
		if(HasControl())
			CrumbActivateWheel();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	private void CrumbActivateWheel()
	{
		ActivateWheel();
	}

	UFUNCTION(BlueprintCallable)
	void StartFollowingSpline()
	{
		bFollowExitSpline = true;
		UnlockMovementFromSpline(this);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateWheel()
	{
		bIsActive = true;

		if(!bHasRemovedCollisionWithSoftReferencedObjects)
			IgnoreSoftReferencedObjects();

		USummitStoneWaterWheelEventHandler::Trigger_OnWheelActivated(this);
	}

	private void IgnoreSoftReferencedObjects()
	{
		for(auto Actor : SoftReferencedActorsToIgnoreMovement)
		{
			if(!Actor.IsValid())
				continue;

			if(Actor.IsPending())
				continue;

			if(Actor.IsNull())
				continue;

			MoveComp.AddMovementIgnoresActor(this, Actor.Get());
		}

		bHasRemovedCollisionWithSoftReferencedObjects = true;
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateWheel()
	{
		bIsActive = false;
	}

	UFUNCTION(BlueprintCallable)
	void HitGate(AHazeActor Gate)
	{
		FSummitStoneWaterWheelOnSmashedThroughGateParams Params;
		Params.Gate = Gate;
		USummitStoneWaterWheelEventHandler::Trigger_OnSmashedThroughGate(this, Params);
	}
};

#if EDITOR
class USummitStoneWaterWheelComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitStoneWaterWheelComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitStoneWaterWheelComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		auto Wheel = Cast<ASummitStoneWaterWheel>(Comp.Owner);
		SetRenderForeground(false);
		DrawWireSphere(Wheel.ActorLocation, Wheel.PlayerCheckRadius * Wheel.CapsuleComp.ShapeScale, FLinearColor::Red, 5, 12);
	}
}
#endif