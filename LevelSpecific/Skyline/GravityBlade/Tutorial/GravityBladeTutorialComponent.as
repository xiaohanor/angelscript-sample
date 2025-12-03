class UGravityBladeTutorialComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bAttackTutorialComplete;

	UPROPERTY(EditAnywhere)
	bool bGrappleTutorialComplete;

	bool bCombatGrappleTutorialComplete;
	TOptional<float> CombatGrappleTutorialOffsetOverride;
	TOptional<bool> bCombatGrappleTutorialStaticLocation;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptAttack;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptGrapple;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptCharge;

	UPROPERTY(EditAnywhere)
	FTutorialPrompt PromptCombatGrapple;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	RemoveTutorial();
		bCombatGrappleTutorialComplete = false;
	}

	UFUNCTION(BlueprintCallable)
	void ShowTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.UnblockCapabilities(n"GravityBladeTutorial", this);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveTutorial()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		Player.BlockCapabilities(n"GravityBladeTutorial", this);
	}
}

namespace GravityBladeTutorial
{
	UFUNCTION(BlueprintCallable)
	void ShowCombatGrappleTutorial(AHazePlayerCharacter Player)
	{
		UGravityBladeTutorialComponent TutorialComp = UGravityBladeTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;
		TutorialComp.bCombatGrappleTutorialComplete = false;
	}

	UFUNCTION(BlueprintCallable)
	void HideCombatGrappleTutorial(AHazePlayerCharacter Player)
	{
		UGravityBladeTutorialComponent TutorialComp = UGravityBladeTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;
		TutorialComp.bCombatGrappleTutorialComplete = true;
	}

	UFUNCTION(BlueprintCallable)
	void CombatGrappleTutorialOverrideOffset(AHazePlayerCharacter Player, float Offset, bool bStatic)
	{
		UGravityBladeTutorialComponent TutorialComp = UGravityBladeTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;
		TutorialComp.CombatGrappleTutorialOffsetOverride.Set(Offset);
		TutorialComp.bCombatGrappleTutorialStaticLocation.Set(bStatic);
	}

	UFUNCTION(BlueprintCallable)
	void CombatGrappleTutorialResetOffset(AHazePlayerCharacter Player, float Offset)
	{
		UGravityBladeTutorialComponent TutorialComp = UGravityBladeTutorialComponent::Get(Player);
		if(TutorialComp == nullptr)
			return;
		TutorialComp.CombatGrappleTutorialOffsetOverride.Reset();
		TutorialComp.bCombatGrappleTutorialStaticLocation.Reset();
	}
}