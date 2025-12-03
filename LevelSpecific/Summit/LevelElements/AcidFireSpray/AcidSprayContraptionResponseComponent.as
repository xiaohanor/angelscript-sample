event void FOnAcidSprayIgnite();

class UAcidSprayContraptionResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnAcidSprayIgnite OnAcidSprayIgnite;

	UFUNCTION()
	void BroadcastSprayIgnite()
	{
		Print("BroadcastSprayIgnite");
		OnAcidSprayIgnite.Broadcast();
	}
}