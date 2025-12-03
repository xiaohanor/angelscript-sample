struct FSanctuaryLightBirdSocketEventData
{
	UPROPERTY(BlueprintReadOnly)
	FVector Location;

	UPROPERTY(BlueprintReadOnly)
	FVector Direction;	
}

class USanctuaryLightBirdSocketEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightBirdEnter(FSanctuaryLightBirdSocketEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLightBirdLeave(FSanctuaryLightBirdSocketEventData EventData)
	{
	}
};

UCLASS(Abstract)
class ASanctuaryLightBirdSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsSpringConstraint SpringConstraint;
	default SpringConstraint.MaximumForce = 1000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot1;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot2;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	ULightBirdTargetComponent LightBirdTargetComp;
	default LightBirdTargetComp.AutoAimMaxAngle = 10.0;

	UPROPERTY(DefaultComponent, Attach = LightBirdTargetComp)
	UTargetableOutlineComponent LightBirdOutline;
	default LightBirdOutline.bOutlineAttachedActors = true;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bExclusiveAttachedIllumination = true;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	UPROPERTY(DefaultComponent)
	USanctuaryInterfaceComponent InterfaceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	FHazeAcceleratedFloat AcceleratedFloat;
	FHazeAcceleratedFloat AttachSpring;

	UPROPERTY(EditAnywhere)
	float TransitionSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	float IdleRotationSpeed = 30.0;

	UPROPERTY(EditAnywhere)
	float ActiveRotationSpeed = 180.0;

	UPROPERTY(EditAnywhere)
	bool bExitOnActiviation = false;

	bool bHasAttachedLightBird = false;
	FVector LightBirdAttachVelocity;
	AAISanctuaryLightBirdCompanion LightBird;

	TArray<FInstigator> DisableInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		LightBirdResponseComp.OnAttached.AddUFunction(this, n"HandleAttached");
		LightBirdResponseComp.OnDetached.AddUFunction(this, n"HandleDetached");
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		LightBirdChargeComp.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
		LightBirdChargeComp.OnChargeDepleted.AddUFunction(this, n"HandleChargeDepleted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo((LightBirdResponseComp.IsIlluminated() ? 1.0 : 0.0), TransitionSpeed, DeltaSeconds);
		float RotationSpeed = Math::Lerp(IdleRotationSpeed, ActiveRotationSpeed, AcceleratedFloat.Value);

		RotationPivot1.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0));
		RotationPivot2.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));

		if (!bHasAttachedLightBird && LightBird != nullptr)
		{
			if (LightBird.AttachParentActor != this)
			{
				LightBirdAttachVelocity = LightBird.ActorVelocity;
			}
			else
			{
				bHasAttachedLightBird = true;
			//	PrintToScreen("Velocity: " + LightBird.ActorVelocity.Size(), 1.0, FLinearColor::Red);
			//	Debug::DrawDebugLine(ActorLocation, ActorLocation + LightBirdAttachVelocity, FLinearColor::Red, 10.0, 1.0);
			
				AttachSpring.SnapTo(0.0, 10.0);
				AcceleratedFloat.SnapTo(1.0, 50.0);

				FSanctuaryLightBirdSocketEventData EventData;
				EventData.Location = Pivot.WorldLocation;
				EventData.Direction = LightBirdAttachVelocity.SafeNormal;
				USanctuaryLightBirdSocketEventHandler::Trigger_OnLightBirdEnter(this, EventData);
			}
		}

		if (bHasAttachedLightBird)
		{
			if (LightBird == nullptr || LightBird.AttachParentActor != this)
			{
				bHasAttachedLightBird = false;

				FVector ToMio = Game::Mio.ActorCenterLocation - Pivot.WorldLocation;

				FSanctuaryLightBirdSocketEventData EventData;
				EventData.Location = Pivot.WorldLocation;
				EventData.Direction = ToMio.SafeNormal;
				USanctuaryLightBirdSocketEventHandler::Trigger_OnLightBirdLeave(this, EventData);
			}			
		}
	
		AttachSpring.SpringTo(0.0, 100.0, 0.2, DeltaSeconds);
		Pivot.SetRelativeLocation(Pivot.WorldTransform.InverseTransformVectorNoScale(LightBirdAttachVelocity.SafeNormal * 100.0) * AttachSpring.Value);
	}

	void UpdateRotation()
	{
		
	}

	UFUNCTION()
	private void HandleAttached()
	{
		auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
		LightBird = UserComp.Companion;
	}

	UFUNCTION()
	private void HandleDetached()
	{
		LightBird = nullptr;
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		InterfaceComp.TriggerActivate();

		if (bExitOnActiviation)
		{
			auto UserComp = ULightBirdUserComponent::Get(Game::Mio);
			UserComp.Hover();
//			UserComp.Companion.CompanionComp.State = ELightBirdCompanionState::LaunchExit;	
		}
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		InterfaceComp.TriggerDeactivate();
	}

	UFUNCTION()
	private void HandleFullyCharged()
	{
	}

	UFUNCTION()
	private void HandleChargeDepleted()
	{
	}

	UFUNCTION()
	void AddDisabler(FInstigator DisableInstigator)
	{
		if (DisableInstigators.Num() == 0)
		{
			LightBirdTargetComp.Disable(this);
			BP_SocketDisabled();
		}

		DisableInstigators.Add(DisableInstigator);
	}

	UFUNCTION()
	void RemoveDisabler(FInstigator DisableInstigator)
	{
		DisableInstigators.Remove(DisableInstigator);

		if (DisableInstigators.Num() == 0)
		{
			LightBirdTargetComp.Enable(this);
			BP_SocketEnabled();
		}
	}

	UFUNCTION()
	void RemoveAllDisablers()
	{
		if (DisableInstigators.Num() > 0)
		{
			LightBirdTargetComp.Enable(this);
		}

		DisableInstigators.Reset();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SocketEnabled() {};

	UFUNCTION(BlueprintEvent)
	void BP_SocketDisabled() {};
};