UCLASS(Abstract)
class UFeatureAnimInstanceBotHanging : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBotHanging Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBotHangingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float VerticalAdditiveValue;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	UHazePhysicalAnimationComponent PhysComp;

	ARemoteHackableWinch Winch;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBotHanging NewFeature = GetFeatureAsClass(ULocomotionFeatureBotHanging);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
		PhysComp.ApplyProfileAsset(this, PhysProfile);

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendspaceValues = GetAnimVector2DParam(n"BotHanging", true);

		if (Winch == nullptr)
		{
			if (Player.AttachParentActor != nullptr)
				Winch = Cast<ARemoteHackableWinch>(Player.AttachParentActor);

			return;
		}

		const float VerticalAdditiveValueTarget = Winch.SyncedHeightVelocity.Value / 600;
		VerticalAdditiveValue = Math::FInterpTo(VerticalAdditiveValue, VerticalAdditiveValueTarget, DeltaTime, 10);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		PhysComp.ClearProfileAsset(this);
	}
}
