enum EMoonMarketRevealableColor
{
	Blue,
	Yellow,
	Neutral
}

class UMoonMarketRevealableComponent : UActorComponent
{
	TArray<AMoonMarketRevealingLantern> Lanterns;

	UStaticMeshComponent MeshComp;
	UHazeSkeletalMeshComponentBase SkeletalMeshComp;

	UPROPERTY(EditAnywhere)
	EMoonMarketRevealableColor PlatformType = EMoonMarketRevealableColor::Blue;

	UPROPERTY(EditAnywhere)
	bool bCanCollide = false;

	TPerPlayer<bool> PlayerCanCollide;

	UPROPERTY(BlueprintReadOnly)
	bool bIsVisible = false;
	
	float CurrentOpacity = 1;
	float TargetOpacity = 1;
	const float FadeInSpeed = 0.5;

	//Audio
	UFUNCTION(BlueprintPure)
	float GetOpacity() const
	{
		return CurrentOpacity;
	}	


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerCanCollide[Game::Mio] = true;
		PlayerCanCollide[Game::Zoe] = true;

		if(bCanCollide)
			TListedActors<AMoonMarketRevealableActors>().Single.AddRevealableCollider(this);

		MeshComp = UStaticMeshComponent::Get(Owner);
		SkeletalMeshComp = UHazeSkeletalMeshComponentBase::Get(Owner);
		Lanterns = TListedActors<AMoonMarketRevealingLantern>().Array;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bIsVisible = false;

		for(int i = 0; i < Lanterns.Num(); i++)
		{
			if (PlatformType != EMoonMarketRevealableColor::Neutral)
				if(Lanterns[i].PlatformType != PlatformType)
					continue;

			SetLanternMaterialParameters(i, Lanterns[i]);

			if(bIsVisible)
				continue;

			float Dist = Lanterns[i].ActorLocation.Distance(Owner.ActorLocation);
			if(Dist <= Lanterns[i].CurrentRevealRadius.Value)
				bIsVisible = true;
		}

		if(CurrentOpacity != TargetOpacity)
		{
			CurrentOpacity = Math::FInterpConstantTo(CurrentOpacity, TargetOpacity, DeltaSeconds, FadeInSpeed);
			
			if(SkeletalMeshComp != nullptr)
			{
				SkeletalMeshComp.SetScalarParameterValueOnMaterials(n"Alpha", CurrentOpacity);
			}
			else if(MeshComp != nullptr)
			{
				MeshComp.SetScalarParameterValueOnMaterials(n"Alpha", CurrentOpacity);
			}
		}
	}

	
	void SetLanternMaterialParameters(int Index, AMoonMarketRevealingLantern Lantern)
	{
		FName PosParam(f"LanternPos{Index}");
		FName RadiusParam(f"LanternRadius{Index}");

		if(SkeletalMeshComp != nullptr)
		{
			SkeletalMeshComp.SetVectorParameterValueOnMaterials(PosParam, Lantern.ActorLocation);
			SkeletalMeshComp.SetScalarParameterValueOnMaterials(RadiusParam, Lantern.CurrentRevealRadius.Value);
		}
		else if(MeshComp != nullptr)
		{
			MeshComp.SetVectorParameterValueOnMaterials(PosParam, Lantern.ActorLocation);
			MeshComp.SetScalarParameterValueOnMaterials(RadiusParam, Lantern.CurrentRevealRadius.Value);
		}
	}

	void StartFadingIn()
	{
		TargetOpacity = 0.5;
		CurrentOpacity = 0;
	}

	void FadeOut()
	{
		TargetOpacity = 0;
	}
};