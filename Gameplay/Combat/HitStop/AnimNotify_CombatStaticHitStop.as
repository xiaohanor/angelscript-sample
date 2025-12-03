class UAnimNotify_CombatStaticHitStop : UAnimNotify
{
	UPROPERTY(EditAnywhere)
	float Duration = 0.1;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true; //Preview	

		// TODO: This is temp
		if (Console::GetConsoleVariableInt("Haze.Skyline.UseCombatTweaks") == 0)
			return true;
		
		auto HitStopComp = UCombatHitStopComponent::Get(MeshComp.Owner);
		if (HitStopComp != nullptr)
			HitStopComp.ApplyHitStop(Animation, Duration);
		return true;
	}
}