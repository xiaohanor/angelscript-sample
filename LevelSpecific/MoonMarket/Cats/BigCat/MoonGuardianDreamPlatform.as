class AMoonGuardianDreamPlatform : ARevealablePlatform
{
	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueMat;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface YellowMat;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface NeutralMat;

	UPROPERTY(EditInstanceOnly)
	bool bIsInverse = false;

	UFUNCTION()
	void OnStartedPlayingHarp(UMoonGuardianHarpPlayingComponent PlayerComp)
	{
		EMoonMarketRevealableColor NewColor = EMoonMarketRevealableColor::Neutral;

		for(auto Lantern : TListedActors<AMoonMarketRevealingLantern>().Array)
		{
			if(Lantern.InteractingPlayer != PlayerComp.OwningPlayer)
			{
				if(!bIsInverse)
					continue;
			}
			else
			{
				if(bIsInverse)
					continue;
			}

			if(Lantern.PlatformType == EMoonMarketRevealableColor::Blue)
				NewColor = EMoonMarketRevealableColor::Yellow;
			else
				NewColor = EMoonMarketRevealableColor::Blue;
		}

		RevealComp.PlatformType = NewColor;
		RevealComp.CurrentOpacity = 0.0001;
		RevealComp.TargetOpacity = 0;

		UMaterialInterface MaterialToUse = NeutralMat;

		if(NewColor == EMoonMarketRevealableColor::Blue)
		{
			MaterialToUse = BlueMat;
		}
		else if(NewColor == EMoonMarketRevealableColor::Yellow)
		{
			MaterialToUse = YellowMat;
		}

		MeshComp.SetMaterial(0, MaterialToUse);
	}
};