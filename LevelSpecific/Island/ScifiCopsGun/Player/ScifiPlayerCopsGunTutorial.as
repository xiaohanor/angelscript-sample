
UFUNCTION(Category = "Copsgun")
void ShowCopsGunThrowAndShootTutorial(AHazePlayerCharacter Player)
{
	UScifiPlayerCopsGunTutorialComponent Tutorial = UScifiPlayerCopsGunTutorialComponent::Get(Player);
	if(Tutorial == nullptr)
		return;	

	if(Tutorial.bThrowAndShootTutorialIsActive)
		return;

	if(Tutorial.bThrowAndShootTutorialIsCompleted)
		return;

	Player.ShowTutorialPromptChain(Tutorial.ThrowAndShootTutorial, Player, Tutorial.ThrowAndShootStage);
	Tutorial.bThrowAndShootTutorialIsActive = true;
}

UFUNCTION(Category = "Copsgun")
void HideCopsGunThrowAndShootTutorial(AHazePlayerCharacter Player, bool bIsCompleted)
{
	UScifiPlayerCopsGunTutorialComponent Tutorial = UScifiPlayerCopsGunTutorialComponent::Get(Player);
	if(Tutorial == nullptr)
		return;	

	if(!Tutorial.bThrowAndShootTutorialIsActive)
		return;

	Player.RemoveTutorialPromptByInstigator(Player);
	Tutorial.bThrowAndShootTutorialIsActive = false;
	if(bIsCompleted)
	{
		Tutorial.bThrowAndShootTutorialIsCompleted = true;
	}
}

UFUNCTION(Category = "Copsgun")
void ShowCopsGunThrowTutorial(AHazePlayerCharacter Player)
{
	UScifiPlayerCopsGunTutorialComponent Tutorial = UScifiPlayerCopsGunTutorialComponent::Get(Player);
	if(Tutorial == nullptr)
		return;

	if(Tutorial.bThrowTutorialIsActive)
		return;

	if(Tutorial.bThrowTutorialIsCompleted)
		return;

	Player.ShowTutorialPrompt(Tutorial.ThrowTutorial, Player);
	Tutorial.bThrowTutorialIsActive = true;
}

UFUNCTION(Category = "Copsgun")
void HideCopsGunThrowTutorial(AHazePlayerCharacter Player, bool bIsCompleted)
{
	UScifiPlayerCopsGunTutorialComponent Tutorial = UScifiPlayerCopsGunTutorialComponent::Get(Player);

	if(Tutorial == nullptr)
		return;	

	if(!Tutorial.bThrowTutorialIsActive)
		return;

	Player.RemoveTutorialPromptByInstigator(Player);
	Tutorial.bThrowTutorialIsActive = false;
	if(bIsCompleted)
	{
		Tutorial.bThrowTutorialIsCompleted = true;
	}

}

UCLASS(Abstract, HideCategories="Activation ComponentTick Variable Cooking ComponentReplication AssetUserData Collision")
class UScifiPlayerCopsGunTutorialComponent : UActorComponent
{	
	//default PrimaryComponentTick.bStartWithTickEnabled = false;

	AHazePlayerCharacter PlayerOwner;
	UScifiPlayerCopsGunManagerComponent CopsGunComp;

	// Throw and Shoot Tutorial
	UPROPERTY()
	FTutorialPromptChain ThrowAndShootTutorial;

	int ThrowAndShootStage = 0;
	bool bThrowAndShootTutorialIsActive = false;
	bool bThrowAndShootTutorialIsCompleted = false;

	// Throw Tutorial
	UPROPERTY()
	FTutorialPrompt ThrowTutorial;

	bool bThrowTutorialIsActive = false;
	bool bThrowTutorialIsCompleted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CopsGunComp = UScifiPlayerCopsGunManagerComponent::Get(Owner);
		check(CopsGunComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Throw Tutorial
		if(bThrowTutorialIsActive && !bThrowTutorialIsCompleted)
		{
			
		}

		// Throw And Shoot Tutorial
		if(bThrowAndShootTutorialIsActive && !bThrowAndShootTutorialIsCompleted)
		{
			if(ThrowAndShootStage == 0)
			{
				//if(PlayerOwner.)
				if(!(CopsGunComp.WeaponsAreAttachedToPlayerThigh() || CopsGunComp.WeaponsAreAttachedToPlayer()))
				{
					ThrowAndShootStage = 1;
					PlayerOwner.SetTutorialPromptChainPosition(PlayerOwner, ThrowAndShootStage);
				}
			}
			
			else if(ThrowAndShootStage == 1)
			{
				if(CopsGunComp.WeaponsAreAttachedToPlayerThigh() || CopsGunComp.WeaponsAreAttachedToPlayer())
				{
					ThrowAndShootStage = 0;
					PlayerOwner.SetTutorialPromptChainPosition(PlayerOwner, ThrowAndShootStage);
				}
			}
		}
	}
}
