event void FSanctuaryWeeperArtifaceResponseSignature(ASanctuaryWeeperArtifact Artifact);


class USanctuaryWeeperArtifactResponseComponent : USceneComponent
{
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperArtifaceResponseSignature OnIlluminated;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperArtifaceResponseSignature OnStopIlluminated;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperArtifaceResponseSignature OnAddedIlluminator;
		UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperArtifaceResponseSignature OnRemovedIlluminator;

	// TInstigated<bool> bIsAffected;
	TArray<FInstigator> Illuminators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::Players)
		{
			auto UserComp = USanctuaryWeeperArtifactUserComponent::GetOrCreate(Player);
			UserComp.ArtifactResponseComps.Add(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			auto UserComp = USanctuaryWeeperArtifactUserComponent::GetOrCreate(Player);
			UserComp.ArtifactResponseComps.Remove(this);
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsIlluminated() const
	{
		return Illuminators.Num() != 0;
	}

	void AddAffector(ASanctuaryWeeperArtifact Artifact)
	{
		bool bWasAffected = IsIlluminated();
		if(Illuminators.AddUnique(Artifact))
			OnAddedIlluminator.Broadcast(Artifact);

		if(!bWasAffected && IsIlluminated())
			OnIlluminated.Broadcast(Artifact);

			
	}
	void RemoveAffector(ASanctuaryWeeperArtifact Artifact)
	{
		bool bWasAffected = IsIlluminated();
		if(Illuminators.Contains(Artifact))
		{
			Illuminators.Remove(Artifact);
			OnRemovedIlluminator.Broadcast(Artifact);
		}


		if(bWasAffected && !IsIlluminated())
			OnStopIlluminated.Broadcast(Artifact);

	}
};