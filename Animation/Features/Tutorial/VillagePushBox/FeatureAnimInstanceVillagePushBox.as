UCLASS(Abstract)
class UFeatureAnimInstanceVillagePushBox : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureVillagePushBox Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureVillagePushBoxAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStruggle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPush;

	UVillagePushableBoxPlayerComponent BoxPushPlayerComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		BoxPushPlayerComp = UVillagePushableBoxPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureVillagePushBox NewFeature = GetFeatureAsClass(ULocomotionFeatureVillagePushBox);
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

		bStruggle = BoxPushPlayerComp.bStruggling;
		bPush = BoxPushPlayerComp.bPushing;
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
