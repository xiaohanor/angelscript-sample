event void FOnPolymorphTriggered();
event void FOnUnmorphed();


class UPolymorphResponseComponent : UActorComponent
{
	FOnPolymorphTriggered OnPolymorphTriggered;
	FOnUnmorphed OnUnmorphed;
	int MorphCount = 0;
	float UnmorphedTime = 0;
	const float Cooldown = 0.5;

	float LastMorphTime;
	const float PolymorphDuration = 30;

	UMoonMarketPolymorphAutoAimComponent AimComp;

	UMoonMarketShapeshiftComponent ShapeshiftComp;

	TSubclassOf<AHazeActor> DesiredMorphClass;

	AHazePlayerCharacter InstigatingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AimComp = UMoonMarketPolymorphAutoAimComponent::Get(Owner);
		ShapeshiftComp = UMoonMarketShapeshiftComponent::GetOrCreate(Owner);
	}

	UFUNCTION(NetFunction)
	void NetRequestPolymorph(TSubclassOf<AHazeActor> Morph, AHazePlayerCharacter Instigator)
	{
		if(!HasControl())
			return;

		if(!ShapeshiftComp.CanShapeshift())
			return;

		CrumbPolymorph(Morph, Instigator);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPolymorph(TSubclassOf<AHazeActor> Morph, AHazePlayerCharacter Instigator)
	{
		InstigatingPlayer = Instigator;
		DesiredMorphClass = Morph;
		OnPolymorphTriggered.Broadcast();
	}
};