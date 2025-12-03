UCLASS(Abstract)
class UMoonMarketPolymorphPotionComponent : UActorComponent
{
	UPROPERTY()
	TPerPlayer<USkeletalMesh> PlayerMesh;

	AHazePlayerCharacter Player;

	bool bSetupFinished = false;
	bool bIsTransformed = false;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent MorphEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent UnMorphEvent;
	private FHazeAudioFireForgetEventParams AudioParams;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		float PanningValue = Player.IsMio() ? -1.0 : 1.0;
		PanningValue *= Audio::GetPanningRuleMultiplier();

		AudioParams.RTPCs.Add(FHazeAudioRTPCParam(Audio::Rtpc_SpeakerPanning_LR, PanningValue));
		AudioParams.RTPCs.Add(FHazeAudioRTPCParam(Audio::Rtpc_Spatialization_SpeakerPanning_Mix, 0.0));
		AudioParams.AttachComponent = Player.Mesh;
		AudioParams.AttenuationScaling = 5000;
	}

	void Morph()
	{
		bIsTransformed = true;
		Player.Mesh.SetSkeletalMeshAsset(PlayerMesh[Player.GetOtherPlayer()]);
		Player.Mesh.ResetAllMaterialOverrides();
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnMorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams("PlayerSwap", Cast<AHazeActor>(Owner)));

		AudioComponent::PostFireForget(MorphEvent, AudioParams);

		if(!bSetupFinished)
		{
			UPlayerHealthComponent::Get(Player).OnFinishDying.AddUFunction(this, n"Unmorph");
			UMoonMarketShapeshiftComponent::Get(Player).OnShapeShift.AddUFunction(this, n"Unmorph");
			bSetupFinished = true;
		}
	}

	UFUNCTION()
	void Unmorph()
	{
		if(UMoonMarketShapeshiftComponent::Get(Player).IsShapeshiftActive())
		{
			//Special case! Do not unset mesh if you are eating balloon candy
			if(Cast<AMoonMarketCandyBalloonForm>(UMoonMarketShapeshiftComponent::Get(Player).ShapeshiftShape.CurrentShape) != nullptr)
				return;
		}

		Player.Mesh.SetSkeletalMeshAsset(PlayerMesh[Player]);
		Player.Mesh.ResetAllMaterialOverrides();
		bIsTransformed = false;
		UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnUnmorph(Cast<AHazeActor>(Owner), FMoonMarketPolymorphEventParams("PlayerSwap", Cast<AHazeActor>(Owner)));
		AudioComponent::PostFireForget(UnMorphEvent, AudioParams);
	}
};