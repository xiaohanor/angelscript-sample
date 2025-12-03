UCLASS(Abstract)
class UFeatureAnimInstanceCopsGunThrow : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCopsGunThrow Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCopsGunThrowAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrow;

	UScifiPlayerCopsGunManagerComponent CopsGunComponent;
	float StartThrowGameTime = 0;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCopsGunThrow NewFeature = GetFeatureAsClass(ULocomotionFeatureCopsGunThrow);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CopsGunComponent = UScifiPlayerCopsGunManagerComponent::Get(Player);
		bThrow = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		if(!CopsGunComponent.WeaponsAreAttachedToPlayer() && !bThrow)
		{
			bThrow = true;
			StartThrowGameTime = Time::GameTimeSeconds;
		}
		else if(bThrow && Time::GetGameTimeSince(StartThrowGameTime) > 0.25)
		{
			bThrow = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (!bThrow)
			return true;
		
		return TopLevelGraphRelevantStateName == n"Throw" && TopLevelGraphRelevantAnimTimeRemaining < 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{

	}
}
