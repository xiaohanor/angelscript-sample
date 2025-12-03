class UAnimNotify_MonkeyCongaFootstep : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Creature_Tundra_Shapeshift_MonkeyRealm_MonkeyConga_SoundDef;

	UGameplay_Creature_Tundra_Shapeshift_MonkeyRealm_MonkeyConga_SoundDef GetCongaSoundDef() const property
	{
		return Cast<UGameplay_Creature_Tundra_Shapeshift_MonkeyRealm_MonkeyConga_SoundDef>(SoundDef);
	}
	
	UPROPERTY(EditInstanceOnly)
	EFootType Foot = EFootType::None;

	bool GetbIsPlant() const property
	{
		return Foot == EFootType::Left || Foot == EFootType::Right;
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Foot == EFootType::None)
			return false;

		if(SoundDef == nullptr)
			return false;

		if(bIsPlant)
			CongaSoundDef.OnFootstep_Plant();
		else
			CongaSoundDef.OnFootstep_Release();

		return true;
	}
}