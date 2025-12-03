event void FAIslandShootableActivatorSignature();

class AIslandShootableActivator : AHazeActor
{
	
	UPROPERTY()
	FAIslandShootableActivatorSignature OnImpact;
	UPROPERTY()
	FAIslandShootableActivatorSignature OnActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent InteractionMesh;

	UPROPERTY(DefaultComponent, Attach = InteractionMesh)
	UIslandRedBlueImpactCounterResponseComponent RedBlueComponent;

	UPROPERTY(DefaultComponent, Attach = InteractionMesh)
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.OptionalShape = FHazeShapeSettings::MakeBox(FVector(40, 40, 40));

	UPROPERTY(EditAnywhere)
	EIslandRedBlueWeaponType BlockColor;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	float CurrentAlpha;
	AHazePlayerCharacter LastPlayerImpacter;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(BlockColor == EIslandRedBlueWeaponType::Red)
			TargetableComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
		else if(BlockColor == EIslandRedBlueWeaponType::Blue)
			TargetableComp.UsableByPlayers = EHazeSelectPlayer::Mio;
		else
			TargetableComp.UsableByPlayers = EHazeSelectPlayer::None;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RedBlueComponent.OnImpactEvent.AddUFunction(this, n"ShieldImpact");
		RedBlueComponent.OnFullAlpha.AddUFunction(this, n"ShieldDeactived");
		RedBlueComponent.BlockImpactForColor(BlockColor, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (LastPlayerImpacter != nullptr)
			CurrentAlpha = RedBlueComponent.GetImpactAlpha(LastPlayerImpacter);
	}

	UFUNCTION()
	void ShieldImpact(FIslandRedBlueImpactResponseParams Data)
	{
		LastPlayerImpacter = Data.Player;
		OnImpact.Broadcast();
	}

	UFUNCTION()
	private void ShieldDeactived(AHazePlayerCharacter Player)
	{
		OnActivated.Broadcast();
	}

}