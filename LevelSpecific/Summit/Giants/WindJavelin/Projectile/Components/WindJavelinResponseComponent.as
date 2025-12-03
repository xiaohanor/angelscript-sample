struct FWindJavelinEventData
{
	FVector Origin;
	FVector Force;
}

struct FWindJavelinResponseComponentData
{
	UWindJavelinResponseComponent Component;
	bool bIsActive = false;

	FWindJavelinResponseComponentData(UWindJavelinResponseComponent InComponent)
	{
		Component = InComponent;
	}
}

enum EWindJavelinWiggleAxis
{
	Pitch,
	Yaw,
	Roll
}

event void FHitByWindJavelin(FWindJavelinHitEventData IcicleHitData);
event void FWindJavelinAttachDetach(AActor WindJavelin);
event void FWindEnterExit(AActor WindJavelin);
event void FWindJavelinForce(FWindJavelinEventData Data);
event void FWindJavelinStartBeingAimedAt();
event void FWindJavelinStopBeingAimedAt();

class UWindJavelinResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = true;

    UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Lifetime")
	bool bSetWindJavelinLifetime = false;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Lifetime", meta = (EditCondition = "bSetWindJavelinLifetime"))
	float WindJavelinLifetime = 5.0;

	UPROPERTY(Category = "Wind Javelin Response Component", meta = (BPCannotCallEvent))
	FHitByWindJavelin OnHitByWindJavelin;

	UPROPERTY()
	FWindJavelinAttachDetach OnWindJavelinAttach;

	UPROPERTY()
	FWindJavelinAttachDetach OnWindJavelinDetach;

	UPROPERTY()
	FWindEnterExit OnEnterWindCone;

	UPROPERTY()
	FWindEnterExit OnExitWindCone;

	UPROPERTY()
	FWindJavelinForce OnApplyForce;

	UPROPERTY()
	FWindJavelinStartBeingAimedAt OnStartBeingAimedAt;

	UPROPERTY()
	FWindJavelinStopBeingAimedAt OnStopBeingAimedAt;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Faux Physics")
	bool bAffectFauxPhysics = true;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Faux Physics", meta = (EditCondition = "bAffectFauxPhysics"))
	float ForceMultiplier = 1.0;

	AActor AttachedWindJavelin;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Wiggle")
	protected bool bEnableWiggle = true;

	// Either assign a component name here, or call SetWiggleComponent() in code
	UPROPERTY(EditDefaultsOnly, Category = "Wind Javelin Response Component|Wiggle", Meta = (EditCondition = "bEnableWiggle"))
	protected FComponentReference WiggleComponentRef;
	protected USceneComponent WiggleComponent;
	protected FRotator WiggleComponentInitialRelativeRotation;
	protected FHazeAcceleratedFloat AccWiggleIntensity;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Wiggle", Meta = (EditCondition = "bEnableWiggle"))
	float WiggleFrequency = 10.0;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Wiggle", Meta = (EditCondition = "bEnableWiggle"))
	float WiggleAmplitude = 2.0;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Wiggle", Meta = (EditCondition = "bEnableWiggle"))
	float StartWigglingDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Wind Javelin Response Component|Wiggle", Meta = (EditCondition = "bEnableWiggle"))
	EWindJavelinWiggleAxis WiggleAxis = EWindJavelinWiggleAxis::Pitch;

	UIceBowPlayerComponent IceBowPlayerComp_Cached;
	UWindJavelinPlayerComponent WindJavelinPlayerComp_Cached;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetWindJavelinPlayerComp();

		if(WiggleComponent == nullptr && WiggleComponentRef.ComponentProperty != NAME_None)
			WiggleComponent = Cast<USceneComponent>(WiggleComponentRef.GetComponent(Owner));

		if(WiggleComponent != nullptr)
			WiggleComponentInitialRelativeRotation = WiggleComponent.RelativeRotation;
	}

	UFUNCTION(BlueprintCallable)
	void SetWiggleComponent(USceneComponent InWiggleComponent)
	{
		if(WiggleComponent != nullptr)
			WiggleComponent.SetRelativeRotation(WiggleComponentInitialRelativeRotation);

		WiggleComponent = InWiggleComponent;

		if(WiggleComponent != nullptr)
			WiggleComponentInitialRelativeRotation = WiggleComponent.RelativeRotation;
	}

	void AttachWindJavelin(AActor WindJavelin)
	{
		AttachedWindJavelin = WindJavelin;
		OnWindJavelinAttach.Broadcast(WindJavelin);
	}

	void DetachWindJavelin(AActor WindJavelin)
	{
		AttachedWindJavelin = nullptr;
		OnWindJavelinDetach.Broadcast(WindJavelin);
	}

	void EnterWindCone(AActor WindJavelin)
	{
		OnEnterWindCone.Broadcast(WindJavelin);
	}

	void ExitWindCone(AActor WindJavelin)
	{
		OnExitWindCone.Broadcast(WindJavelin);
	}

	void ApplyForce(FWindJavelinEventData Data)
	{
		OnApplyForce.Broadcast(Data);

		// if(bAffectFauxPhysics)
		// 	ApplyFauxForceToActorAt(Owner, Data.Origin, Data.Force * ForceMultiplier);
	}

	void StartBeingAimedAt()
	{
		OnStartBeingAimedAt.Broadcast();
	}

	void StopBeingAimedAt()
	{
		OnStopBeingAimedAt.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bEnableWiggle)
			TickWiggle(DeltaSeconds);
	}

	private void TickWiggle(float DeltaTime)
	{
		if(WiggleComponent == nullptr)
			return;

		bool bWiggle = ShouldWiggle();

		if(!bWiggle && AccWiggleIntensity.Value < KINDA_SMALL_NUMBER)
			return;

		// Lerp wiggle intensity for smooth fade in/out
		AccWiggleIntensity.AccelerateTo(bWiggle ? 1.0 : 0.0, StartWigglingDuration, DeltaTime);

		if(!bWiggle && AccWiggleIntensity.Value < KINDA_SMALL_NUMBER)
		{
			// If we want to stop wiggling, and the intensity has reached 0
			WiggleComponent.SetRelativeRotation(WiggleComponentInitialRelativeRotation);
		}
		else
		{
			FRotator Offset = GetWiggleOffset();
			WiggleComponent.SetRelativeRotation(WiggleComponentInitialRelativeRotation.Compose(Offset));
		}
	}

	bool ShouldWiggle()
	{
		if(GetWindJavelinPlayerComp() != nullptr)
			return GetWindJavelinPlayerComp().bIsAiming;

		if(GetIceBowPlayerComp() != nullptr)
			return GetIceBowPlayerComp().bIsAimingIceBow;

		return false;
	}

	FRotator GetWiggleOffset()
	{
		const float Offset = Math::Sin(Time::GameTimeSeconds * WiggleFrequency) * WiggleAmplitude * AccWiggleIntensity.Value;

		switch(WiggleAxis)
		{
			case EWindJavelinWiggleAxis::Pitch: return FRotator(Offset, 0.0, 0.0);
			case EWindJavelinWiggleAxis::Yaw: 	return FRotator(0.0, Offset, 0.0);
			case EWindJavelinWiggleAxis::Roll: 	return FRotator(0.0, 0.0, Offset);
		}
	}

	UIceBowPlayerComponent GetIceBowPlayerComp()
	{
		if(IceBowPlayerComp_Cached != nullptr)
			return IceBowPlayerComp_Cached;

		IceBowPlayerComp_Cached = UIceBowPlayerComponent::Get(Game::GetPlayer(IceBow::Player));

		return IceBowPlayerComp_Cached;
	}

	UWindJavelinPlayerComponent GetWindJavelinPlayerComp()
	{
		if(WindJavelinPlayerComp_Cached != nullptr)
			return WindJavelinPlayerComp_Cached;

		WindJavelinPlayerComp_Cached = UWindJavelinPlayerComponent::Get(WindJavelin::GetPlayer());

		return WindJavelinPlayerComp_Cached;
	}
}