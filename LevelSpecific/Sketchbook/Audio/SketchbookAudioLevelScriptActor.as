class ASketchbookAudioLevelScriptActor : AAudioLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	UPhysicalMaterialAudioAsset SketchbookOverrideMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();	

		for(auto Player : Game::GetPlayers())
		{
			auto PlayerMaterialComp = UPlayerAudioMaterialComponent::Get(Player);
			PlayerMaterialComp.SetAllMaterialOverride(SketchbookOverrideMaterial, FInstigator(this));

			auto PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
			PlayerMoveAudioComp.RequestBlockMovement(this, EMovementAudioFlags::Falling);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for(auto Player : Game::GetPlayers())
		{
			auto PlayerMoveAudioComp = UPlayerMovementAudioComponent::Get(Player);
			PlayerMoveAudioComp.RequestUnBlockMovement(this, EMovementAudioFlags::Falling);
		}
	}
}