
event void FScifiGravityGrenadeImpactResponseSignature(AHazePlayerCharacter ImpactInstigator, UScifiGravityGrenadeTargetableComponent Component);


class UScifiGravityGrenadeImpactResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Impact")
	FScifiGravityGrenadeImpactResponseSignature OnImpact;

	void OnApplyImpact(AHazePlayerCharacter FromPlayer, UScifiGravityGrenadeTargetableComponent Target)
	{
		OnImpact.Broadcast(FromPlayer, Target);
		Print("Aj", 5);
	}
}