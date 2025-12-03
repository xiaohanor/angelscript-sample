/**
 * Manages the player being split into two halves
 * That's why it is Tooth Split, not Split Tooth c;
 */
UCLASS(Abstract, HideCategories = "ComponentTick Debug Activation Cooking Disable Tags Navigation Variable")
class UDentistToothSplitComponent : UActorComponent
{
	access Split = private, UDentistToothSplitCapability;

	UPROPERTY(EditDefaultsOnly, Category = "Player")
	TPerPlayer<USkeletalMesh> SplitToothPlayerMeshes;

	UPROPERTY(EditDefaultsOnly, Category = "AI")
	TPerPlayer<TSubclassOf<ADentistSplitToothAI>> SplitToothAIClass;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference MioToothSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ZoeToothSoundDef;

	bool bShouldSplit = false;
	bool bIsSplit = false;
	
	float SplitStartTime = 0;

	private AHazePlayerCharacter Player;
	private UDentistSplitToothComponent PlayerSplitToothComp;

	ADentistSplitToothAI SplitToothAI;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		if(Player.IsMio())
		{
			MioToothSoundDef.SpawnSoundDefAttached(Player,Owner);
		}
		else
		{
			ZoeToothSoundDef.SpawnSoundDefAttached(Player,Owner);
		}
	}

	AHazePlayerCharacter GetPlayerSplitTooth() const
	{
		return Player;
	}

	ADentistSplitToothAI GetSplitToothAI() const
	{
		return SplitToothAI;
	}

	UDentistSplitToothComponent GetPlayerSplitToothComp() const
	{
		return UDentistSplitToothComponent::Get(Player);
	}

	UDentistSplitToothComponent GetSplitToothCompAI() const
	{
		return SplitToothAI.SplitToothComp;
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void SplitTooth()
	{
		bShouldSplit = true;
	}

	UFUNCTION(DevFunction)
	void RecombineTeeth()
	{
		bShouldSplit = false;
	}
#endif
};