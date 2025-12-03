enum ETailDragonClimbFootType
{
	Plant,
	Release,
	EnterLand,
	Enter,
	Dash
}

class UAnimNotify_TailDragonFootstepClimb : UAnimNotify_HazeSoundDefTrigger
{
	default SoundDefClass = UGameplay_Vehicle_Player_Dragon_Teen_SoundDef;

	UPROPERTY(EditInstanceOnly)
	ETailDragonClimbFootType Type;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		ATeenDragon Dragon = Cast<ATeenDragon>(MeshComp.GetOwner());
		if(Dragon == nullptr)
			return false;

		UGameplay_Vehicle_Player_Dragon_Teen_SoundDef DragonSoundDef = Cast<UGameplay_Vehicle_Player_Dragon_Teen_SoundDef>(SoundDef);
		if(DragonSoundDef == nullptr)
			return false;

		switch(Type)
		{
			case(ETailDragonClimbFootType::Plant): DragonSoundDef.OnFootstepPlant_Climb(); break;	
			case(ETailDragonClimbFootType::Release): DragonSoundDef.OnFootstepRelease_Climb(); break;		
			case(ETailDragonClimbFootType::EnterLand): DragonSoundDef.OnFootstepEnterLand_Climb(); break;
			case(ETailDragonClimbFootType::Enter): DragonSoundDef.OnFootstepEnter_Climb(); break;
			case(ETailDragonClimbFootType::Dash): DragonSoundDef.OnFootstepEnter_Dash(); break;
			default: break;
		}

		return true;
	}
}