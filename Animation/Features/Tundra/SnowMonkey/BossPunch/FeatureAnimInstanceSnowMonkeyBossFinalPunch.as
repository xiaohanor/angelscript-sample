UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyBossFinalPunch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyBossFinalPunch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyBossFinalPunchAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDoBackFlip = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPunchingThisFrame = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldPlayLastFinalPunch = false;

	UTundraPlayerSnowMonkeyIceKingBossPunchComponent BossPunchComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(HazeOwningActor.AttachParentActor);
		if (BossPunchComp==nullptr)  
		BossPunchComp = UTundraPlayerSnowMonkeyIceKingBossPunchComponent::GetOrCreate(Game::Mio);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyBossFinalPunch NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyBossFinalPunch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bDoBackFlip = BossPunchComp.AnimData.bDoBackFlip;
		bPunchingThisFrame = BossPunchComp.AnimData.bPunchingThisFrame;
		bShouldPlayLastFinalPunch = BossPunchComp.AnimData.bShouldPlayLastFinalPunch;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
