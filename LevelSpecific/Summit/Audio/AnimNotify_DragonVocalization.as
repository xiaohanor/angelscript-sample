enum EDragonVocalizationType
{
	None,
	Idle_Small,
	Idle_Medium,
	Idle_Large,
	Jump,
	Land,
	Hurt,
	Angry_Small,
	Angry_Medium,
	Angry_Large
	// HEJ PHILIP HÄR KAN DU SKRIVA IN FLERA ALTERNATIV I TEXT :)
}

struct FDragonVocalizationParams
{
	UPROPERTY()
	EDragonVocalizationType Type;
}

class UAnimNotify_DragonVocalization : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Character_Creature_Player_Dragon_Vocalizations_Teen_SoundDef;

	UPROPERTY(EditInstanceOnly)
	EDragonVocalizationType Type;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{		
		UGameplay_Character_Creature_Player_Dragon_Vocalizations_Teen_SoundDef DragonSoundDef = Cast<UGameplay_Character_Creature_Player_Dragon_Vocalizations_Teen_SoundDef>(SoundDef);
		if(DragonSoundDef == nullptr)
			return false;

		if(Type == EDragonVocalizationType::None)
			return false;

		FDragonVocalizationParams Params;
		Params.Type = Type;

		DragonSoundDef.OnVocalization(Params);
		return true;
	}
}