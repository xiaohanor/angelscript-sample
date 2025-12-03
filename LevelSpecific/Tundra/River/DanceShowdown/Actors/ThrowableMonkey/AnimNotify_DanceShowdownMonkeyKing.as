//GRAB--------------------------------------------

class UAnimNotify_DanceShowdownMonkeyKingGrabLeft : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner).GrabMonkey(Game::GetMio());
		return true;
	}
}

class UAnimNotify_DanceShowdownMonkeyKingGrabRight : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner).GrabMonkey(Game::GetZoe());
		return true;
	}
}

//THROW--------------------------------------------

class UAnimNotify_DanceShowdownMonkeyKingThrowLeft : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner).ThrowMonkey(Game::GetMio());
		return true;
	}
}

class UAnimNotify_DanceShowdownMonkeyKingThrowRight : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				FAnimNotifyEventReference EventReference) const
	{
		if(Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner) == nullptr)
			return false;

		Cast<ADanceShowdownMonkeyKing>(MeshComp.Owner).ThrowMonkey(Game::GetZoe());
		return true;
	}
}