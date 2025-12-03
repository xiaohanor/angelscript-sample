UCLASS(Abstract)
class AAISanctuaryBabyWorm : ABasicAIGroundMovementCharacter
{
	default CapabilityComp.DefaultCapabilities.Add(n"SanctuaryBabyWormBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UCentipedeBiteResponseComponent Bite1Comp;
	UPROPERTY(DefaultComponent)
	UCentipedeBiteResponseComponent Bite2Comp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		Bite2Comp.DisableForPlayer(Game::Mio, this);
		Bite2Comp.DisableForPlayer(Game::Zoe, this);
		Bite1Comp.OnCentipedeBiteStarted.AddUFunction(this, n"Bite1Started");
	}

	UFUNCTION()
	private void Bite1Started(FCentipedeBiteEventParams BiteParams)
	{
		if(Bite1Comp.IsDisabledForPlayer(BiteParams.Player.OtherPlayer))
		{
			Bite1Comp.EnableForPlayer(BiteParams.Player.OtherPlayer, this);
		}
		else
		{
			Bite1Comp.DisableForPlayer(BiteParams.Player.OtherPlayer, this);
			Bite2Comp.EnableForPlayer(BiteParams.Player.OtherPlayer, this);
		}
	}
}