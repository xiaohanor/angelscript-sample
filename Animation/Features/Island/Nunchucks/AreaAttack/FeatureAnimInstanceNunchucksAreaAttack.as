UCLASS(Abstract)
class UFeatureAnimInstanceNunchucksAreaAttack : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureNunchucksAreaAttack Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureNunchucksAreaAttackAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UPlayerIslandNunchuckUserComponent MeleeComponent;

	UPROPERTY(BlueprintReadOnly)
	float AnimationLength;

	UPROPERTY(BlueprintReadOnly)
	float AttackPlayRate;

	UPROPERTY(BlueprintReadOnly)
	int CurrentAttack;

	AHazePlayerCharacter NunchuckPlayer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureNunchucksAreaAttack NewFeature = GetFeatureAsClass(ULocomotionFeatureNunchucksAreaAttack);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Get a reference to the player character, doing this since this AnimInstance will also run on the nunchuck actor
		if (Player != nullptr)
			NunchuckPlayer = Player;
		else {
			// Owner is nunchuck actor 
			auto IslandNunchuckMeshComp = UIslandNunchuckMeshComponent::Get(HazeOwningActor);
			if (IslandNunchuckMeshComp != nullptr)
				NunchuckPlayer = IslandNunchuckMeshComp.PlayerOwner;
		}
		
		MeleeComponent = UPlayerIslandNunchuckUserComponent::Get(NunchuckPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// AnimationLength = MeleeComponent.CurrentActiveMoveTimeMax;
		// AttackPlayRate = MeleeComponent.CurrentActiveMovePlayRate;
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
