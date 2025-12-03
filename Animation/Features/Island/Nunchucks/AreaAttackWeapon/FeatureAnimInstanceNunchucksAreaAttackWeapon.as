UCLASS(Abstract)
class UFeatureAnimInstanceNunchucksAreaAttackWeapon : UHazeAnimInstanceBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY()
	ULocomotionFeatureNunchucksAreaAttackWeapon Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureNunchucksAreaAttackWeaponAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UIslandNunchuckMeshComponent MeleeWeaponComponent;

	UPROPERTY(BlueprintReadOnly)
	float AnimationLength;

	UPROPERTY(BlueprintReadOnly)
	float AttackPlayRate;

	UPROPERTY(BlueprintReadOnly)
	int CurrentAttack;

	int PrevAttack;

	UPROPERTY(BlueprintReadOnly)
	bool PlayAttack;

	UPROPERTY(BlueprintReadOnly)
	bool PlayAreaAttack;

	UPROPERTY(BlueprintReadOnly)
	float NunchuckHandleScale = 1.6;

	//UPROPERTY(BlueprintReadOnly)
	//EScifiMeleeTargetableDirection RelativeTargetDirection = EScifiMeleeTargetableDirection::None;
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (Feature == nullptr)
			return;

		AnimData = Feature.AnimData;

		if(HazeOwningActor != nullptr)
			MeleeWeaponComponent = UIslandNunchuckMeshComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MeleeWeaponComponent == nullptr || MeleeWeaponComponent.PlayerOwner == nullptr)
			return;
		auto MeleeComponent = UPlayerIslandNunchuckUserComponent::Get(MeleeWeaponComponent.PlayerOwner);
		check(false); // Refactor, tyko
		// PrevAttack = CurrentAttack;
		// CurrentAttack = MeleeComponent.GetActiveComboIndex();
		// PrintToScreenScaled("CurrentAttack: " + CurrentAttack, 0.0, Scale = 3.0);
		// AnimationLength = MeleeComponent.CurrentActiveMoveTimeMax;
		// AttackPlayRate = MeleeComponent.CurrentActiveMovePlayRate;
		// RelativeTargetDirection = MeleeComponent.PrimaryTargetRelativeDirection;
		// PlayAttack = MeleeWeaponComponent.PlayerOwner.Mesh.CurrentFeatureMatchesAnimationRequest(n"NunchucksCombo");
		// PlayAreaAttack = MeleeWeaponComponent.PlayerOwner.Mesh.CurrentFeatureMatchesAnimationRequest(n"NunchucksAreaAttack");
	}
}
