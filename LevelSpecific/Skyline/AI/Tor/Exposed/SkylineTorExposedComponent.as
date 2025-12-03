event void FSkylineTorExposedComponentOnExposedDamageSignature();

class USkylineTorExposedComponent : UActorComponent
{
	UBasicAIHealthComponent HealthComp;
	USkylineTorPhaseComponent PhaseComp;

	private TInstigated<bool> bInternalCanExpose;
	bool bExpose;
	bool bExposed;
	AHazeActor ExposeInstigator;

	UPROPERTY()
	FSkylineTorExposedComponentOnExposedDamageSignature OnExposedDamage;

	UPROPERTY()
	UAnimSequence PlayerFinalJumpSequence;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		PhaseComp = USkylineTorPhaseComponent::GetOrCreate(Owner);
		bInternalCanExpose.SetDefaultValue(false);
	}

	bool GetbCanExpose() property
	{
		return bInternalCanExpose.Get();
	}

	void Start(FInstigator Instigator)
	{
		bExpose = false;
		ExposeInstigator = nullptr;
		bInternalCanExpose.Apply(true, Instigator);
	}
	
	void Reset(FInstigator Instigator)
	{
		bExpose = false;
		ExposeInstigator = nullptr;
		bInternalCanExpose.Clear(Instigator);
	}

	bool GetbFinalExpose() property
	{
		return HealthComp.CurrentHealth <= PhaseComp.HoveringThreshold && PhaseComp.Phase == ESkylineTorPhase::Hovering && PhaseComp.SubPhase == ESkylineTorSubPhase::HoveringSecond;
	}
}