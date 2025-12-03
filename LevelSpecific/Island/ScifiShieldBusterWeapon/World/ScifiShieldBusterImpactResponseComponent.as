
event void FScifiShieldBusterImpactResponseSignature(AHazePlayerCharacter ImpactInstigator, UScifiShieldBusterTargetableComponent Component);


class UScifiShieldBusterImpactResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Impact")
	FScifiShieldBusterImpactResponseSignature OnImpact;

	void OnApplyImpact(AHazePlayerCharacter FromPlayer, UScifiShieldBusterTargetableComponent Target)
	{
		OnImpact.Broadcast(FromPlayer, Target);
	}
}