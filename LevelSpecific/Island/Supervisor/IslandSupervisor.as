UCLASS(Abstract)
class AIslandSupervisor : AHazeActor
{
	access Manager = private, UIslandSupervisorManagerComponent;
	access Capabilities = private, UIslandSupervisorActiveCapability, UIslandSupervisorInactiveCapability, UIslandSupervisorEnterInactiveCapability;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent EyeBall;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UIslandSupervisorCompoundCapability);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandSupervisorVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditDefaultsOnly)
	UIslandSupervisorData Data;

	UPROPERTY(EditDefaultsOnly)
	float MaxRotateAngle = 60.0;

	UPROPERTY(EditAnywhere)
	float PlayerDetectionRange = 1000.0;

	private TArray<FInstigator> ActiveInstigators;
	private UIslandSupervisorManagerComponent Manager;
	private bool bActive = true;
	private FRotator PreviousEyeRotation;
	private float EyeBallRotationRate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PreviousEyeRotation = EyeBall.WorldRotation;
		Manager = UIslandSupervisorManagerComponent::GetOrCreate(Game::Mio);
		if(IsActive())
			OnActivated(true);
		else
			OnDeactivated(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Rate = EyeBall.WorldRotation.AngularDistance(PreviousEyeRotation) / DeltaTime;
		if(Math::IsNearlyZero(Rate, 3.0))
			Rate = 0.0;
		
		if(Rate > 0.0 && EyeBallRotationRate == 0.0)
			UIslandSupervisorEffectHandler::Trigger_OnEyeStartMoving(this);
		else if(Rate == 0.0 && EyeBallRotationRate > 0.0)
			UIslandSupervisorEffectHandler::Trigger_OnEyeStopMoving(this);

		EyeBallRotationRate = Rate;
		PreviousEyeRotation = EyeBall.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		ApplyCurrentEyeColor();
	}

	UFUNCTION()
	void Activate(FInstigator Instigator)
	{
		ActiveInstigators.AddUnique(Instigator);
	}

	UFUNCTION()
	void Deactivate(FInstigator Instigator)
	{
		ActiveInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsActive()
	{
		if(Manager.IsGloballyActive())
			return true;

		return ActiveInstigators.Num() > 0;
	}

	void SetClampedEyeRotation(FRotator UnclampedWorldRotation)
	{
		FVector Forward = UnclampedWorldRotation.ForwardVector.ConstrainToCone(ActorForwardVector, Math::DegreesToRadians(MaxRotateAngle));
		FRotator ClampedRotation = FRotator::MakeFromXZ(Forward, UnclampedWorldRotation.UpVector);
		EyeBall.WorldRotation = ClampedRotation;
	}

	access:Capabilities void OnActivated(bool bInitial = false)
	{
		if(!bInitial && bActive)
			return;

		ApplyCurrentEyeColor();
		bActive = true;
	}

	access:Capabilities void OnDeactivated(bool bInitial = false)
	{
		if(!bInitial && !bActive)
			return;

		ApplyDeactiveEyeColor();
		bActive = false;
	}

	FIslandSupervisorEyeMaterials GetCurrentEyeColor()
	{
		return GetEyeColorFromMood(Mood);
	}

	FIslandSupervisorEyeMaterials GetEyeColorFromMood(EIslandSupervisorMood In_Mood)
	{
		switch(In_Mood)
		{
			case EIslandSupervisorMood::None:
			{
				devError("There is no eye color for mood None");
				return FIslandSupervisorEyeMaterials();
			}
			case EIslandSupervisorMood::Neutral:
			{
				return Data.NeutralMaterials;
			}
			case EIslandSupervisorMood::Happy:
			{
				return Data.HappyMaterials;
			}
			case EIslandSupervisorMood::Angry:
			{
				return Data.AngryMaterials;
			}
		}
	}

	FIslandSupervisorEyeMaterials GetDeactiveEyeColor()
	{
		return Data.DeactiveMaterials;
	}

	void ApplyCurrentEyeColor()
	{
		ApplyEyeColor(GetCurrentEyeColor());
	}

	void ApplyDeactiveEyeColor()
	{
		ApplyEyeColor(GetDeactiveEyeColor());
	}

	void ApplyEyeColor(FIslandSupervisorEyeMaterials EyeColor)
	{
		EyeBall.SetMaterial(1, EyeColor.EyeMainMaterial);
		EyeBall.SetMaterial(2, EyeColor.EyeRimMaterial);
	}

	EIslandSupervisorMood GetMood() const property
	{
		return Manager.GetCurrentMood();
	}

	UFUNCTION(BlueprintPure)
	float AudioGetCurrentEyeRotationRate() const
	{
		return EyeBallRotationRate;
	}
}

#if EDITOR
class UIslandSupervisorVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandSupervisorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandSupervisorVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Supervisor = Cast<AIslandSupervisor>(Component.Owner);
		DrawWireSphere(Supervisor.EyeBall.WorldLocation, Supervisor.PlayerDetectionRange, FLinearColor::Yellow, 3.0);
	}
}
#endif