enum EMoonMarketWandType
{
	None,
	IceBolt,
	Levitate,
	Resizer,
	Polymorph
}

class UWandPlayerComponent : UActorComponent
{
	EMoonMarketWandType Type;

	FWandPlayerData PlayerData;

	UPROPERTY()
	UAnimSequence CastSpellAnim;

	UPROPERTY(EditAnywhere)
	UHazeBoneFilterAsset BoneFilter;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	TSubclassOf<UMoonMarketWandCrosshair> CrosshairClass;

	UMoonMarketWandCrosshair Crosshair;

	bool bHasIceBolt;
	bool bHasLevitate;
	bool bHasResizer;

	AWandBase CurrentWand;

	AActor TargetActor;

	void SetWand(FWandPlayerData Data)
	{
		PlayerData = Data;
		Type = Data.Type;
		CurrentWand = Data.Wand;

		CurrentWand.SetActorRelativeLocation(FVector(2.11, -5.018, 11.086));
		CurrentWand.SetActorRelativeRotation(FRotator(49.4, 105.81, 19.17));
	}

	void ClearWand()
	{
		PlayerData.Player = nullptr;
		PlayerData.Wand = nullptr;
		PlayerData.Type = EMoonMarketWandType::None;
		CurrentWand = nullptr;
	}

	//Override func
	void CastSpell()
	{

	}
};