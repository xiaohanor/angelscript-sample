namespace GentlemanScore
{
	const float Melee = 2.0;
	const float Shooting = 1.0;
}

struct FGentlemanClaim
{
	const UObject Claimant;
	int NumTokens;

	FGentlemanClaim(const UObject _Claimant, int _NumTokens)
	{
		this.Claimant = _Claimant;
		this.NumTokens = _NumTokens;
	}
}

struct FGentlemanSemaphore
{
	TArray<FGentlemanClaim> Claims;
};

class UGentlemanCooldown : UObject
{
	float CooldownTime;
}

// Component to set on player or team when you need to synchronize 
// attacks and other actions between several AIs. 
// Remember to adhere to the Queensberry rules! Pip pip!
class UGentlemanComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(BlueprintHidden, EditAnywhere)
	private TMap<FName, int> MaxAllowedClaimants;

    private TMap<FName, FGentlemanSemaphore> TokenSemaphore;
	
    private TArray<AHazeActor> Opponents;

    // Keeps track of when, if ever, an action with the given tag was performed
    private TMap<FName, float> LastActionTimes;

	private TArray<UGentlemanCooldown> AvailableCooldowns;
	private TArray<UGentlemanCooldown> ActiveCooldowns;

	private TArray<FInstigator> TargetInvalidators;
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float CurTime = Time::GameTimeSeconds;
		for (int i = ActiveCooldowns.Num() - 1; i >= 0; i--)
		{
			if (CurTime > ActiveCooldowns[i].CooldownTime)
			{
				// Release tokens claimed by cooldown
				ClearClaimantFromAllSemaphores(ActiveCooldowns[i]);

				// Cooldown is now available for reuse.
				AvailableCooldowns.Add(ActiveCooldowns[i]);
				ActiveCooldowns.RemoveAtSwap(i);
			}
		}

		if (ActiveCooldowns.Num() == 0)
			SetComponentTickEnabled(false);
	}

	void AddOpponent(AHazeActor Opponent)
	{
		//Print("AddOpponent for " + Owner.Name + " to: " + Opponent.Name);
		Opponents.AddUnique(Opponent);
	}

	void RemoveOpponent(AHazeActor Opponent)
	{
		//Print("RemoveOpponent for " + Owner.Name + " from: " + Opponent.Name);
		Opponents.RemoveSingleSwap(Opponent);
	}

	// Keeps track of which opponents are considering attacking us
	int32 GetNumOpponents()
    {
		return Opponents.Num();
	}

    // Keeps track of which opponents are considering attacking us excluding input opponent
    int32 GetNumOtherOpponents(AHazeActor PotentialOpponent)
    {
        if (Opponents.Contains(PotentialOpponent))
            return Opponents.Num() - 1;
        return Opponents.Num();
    }

	// Returns the opponents array
	TArray<AHazeActor> GetOpponents()
	{
		return Opponents;
	}

    // Let's us know action is being performed
    void ReportAction(const FName& Tag)
    {
        LastActionTimes.Add(Tag, Time::GetGameTimeSeconds());
    }

    // When was action last reported?
    float GetLastActionTime(const FName& Tag)
    {
        float LastTime = 0.0;
        LastActionTimes.Find(Tag, LastTime);
        return LastTime;
    }

	void SetMaxAllowedClaimants(const FName& Token, int MaxNumber)
	{
		MaxAllowedClaimants.Add(Token, MaxNumber);
	}

	int GetMaxAllowedClaimants(const FName& Token)
	{
		int NumClaimants = 1;
		MaxAllowedClaimants.Find(Token, NumClaimants);
		return NumClaimants;
	}

    // Check if token is available to claim 
    bool IsTokenAvailable(const FName& Token, int NumWantedTokens = 1)
    {
		int MaxNumber = 1;
		MaxAllowedClaimants.Find(Token, MaxNumber);
		if (MaxNumber < NumWantedTokens)
			return false;

		int NumClaimed = GetNumberOfClaimedTokens(Token);
		return NumClaimed + NumWantedTokens <= MaxNumber;
    }

	bool HasBeenClaimed() const
	{
		for(auto& Slot : TokenSemaphore)
		{
			if(Slot.GetValue().Claims.Num() > 0)
			{
				return true;
			}
		}
		return false;
	}

	bool IsClaimingAnyToken(UObject Claimant) const
	{
		for(auto& Slot : TokenSemaphore)
		{
			for (FGentlemanClaim Claim : Slot.GetValue().Claims)
			{
				if (Claim.Claimant == Claimant)
					return true;
			}
		}
		return false;
	}

	void GetAllSemaphoreTokens(TArray<FName>& OutTokens) const
	{
		for(auto& Slot : TokenSemaphore)
		{
			OutTokens.Add(Slot.GetKey());
		}
	}

	void ClearClaimantFromAllSemaphores(UObject Claimant) 
	{
		for(auto& Slot : TokenSemaphore)
		{
			FGentlemanSemaphore& Semaphore = Slot.GetValue();
			for (int i = Semaphore.Claims.Num() - 1; i >= 0; i--)
			{
				if (Semaphore.Claims[i].Claimant == Claimant)
				{
					TEMPORAL_LOG(this)
						.Event("Released token " + Slot.GetKey() + " (" + Semaphore.Claims[i].NumTokens + ") by " + (Claimant == nullptr ? n"null" : Claimant.Name));
					Semaphore.Claims.RemoveAtSwap(i);					
					break; // Uniquely added
				}
			}
		}
	}

	// Check if claimant has already claimed token
	bool IsClaimingToken(const FName& Token, UObject Claimant)
	{
		FGentlemanSemaphore Semaphore;
		if (TokenSemaphore.Find(Token, Semaphore)) 
		{
			for (FGentlemanClaim Claim : Semaphore.Claims)
			{
				if (Claim.Claimant == Claimant)
					return true;
			}
		}
		return false;
	}

	// Get all claimants of given token
	bool GetClaimants(const FName& Token, TArray<UObject>& Claimants)
	{
		FGentlemanSemaphore Semaphore;
		if (TokenSemaphore.Find(Token, Semaphore))
		{
			for (FGentlemanClaim Claim : Semaphore.Claims)
			{
				Claimants.Add(Claim.Claimant);
			}
			return true;
		}
		return false;
	}

	int GetNumberOfClaimedTokens(const FName& Token) const
	{
		int nClaimed = 0;
		FGentlemanSemaphore Semaphore;
		if (TokenSemaphore.Find(Token, Semaphore))
		{
			for (FGentlemanClaim Claim : Semaphore.Claims)
			{
				nClaimed += Claim.NumTokens;
			}
		}
		return nClaimed;
	}

	int GetNumberOfAvailableTokens(const FName& Token) const
	{
		int MaxAllowed = 1;
		MaxAllowedClaimants.Find(Token, MaxAllowed);
		return MaxAllowed - GetNumberOfClaimedTokens(Token);
	}

    // Try to claim token. Return true if successful, false if token was unavailable 
    bool ClaimToken(const FName& Token, UObject Claimant, int NumWantedTokens = 1)
    {
		int MaxAllowed = 1;
		MaxAllowedClaimants.Find(Token, MaxAllowed);
		if (MaxAllowed < NumWantedTokens)
			false;

		if (!TokenSemaphore.Contains(Token))
		{
			// No entry, so no claimants yet. Create semaphore
			FGentlemanSemaphore Semaphore;
			Semaphore.Claims.Add(FGentlemanClaim(Claimant, NumWantedTokens));
			TokenSemaphore.Add(Token, Semaphore);
			TEMPORAL_LOG(this)
				.Event("Claimed token " + Token + " (" + NumWantedTokens + ") by " + (Claimant == nullptr ? n"null" : Claimant.Name));
			return true;
		}

        // Check number of claims (excluding ours)
		FGentlemanSemaphore& Semaphore = TokenSemaphore.FindOrAdd(Token);
		int iOwnClaim = -1;
		int nOtherClaimed = 0;
		for (int i = 0; i < Semaphore.Claims.Num(); i++)
		{
			if (Semaphore.Claims[i].Claimant == Claimant)
				iOwnClaim = i;
			else
				nOtherClaimed += Semaphore.Claims[i].NumTokens;
		}

		if (nOtherClaimed + NumWantedTokens <= MaxAllowed)
		{
			// Enough free tokens, claim
			if (Semaphore.Claims.IsValidIndex(iOwnClaim))
				Semaphore.Claims[iOwnClaim].NumTokens = NumWantedTokens;
			else
				Semaphore.Claims.Add(FGentlemanClaim(Claimant, NumWantedTokens));
			TEMPORAL_LOG(this)
				.Event("Claimed token " + Token + " (" + NumWantedTokens + ") by " + (Claimant == nullptr ? n"null" : Claimant.Name));
			return true;
		}

		// Token is claimed by too many others
		return false;
    }

    // Check if we can claim token. Return true if successful, false if not enough tokens are available
    bool CanClaimToken(const FName& Token, const UObject Claimant, int NumWantedTokens = 1) const
    {
		int MaxAllowed = 1;
		MaxAllowedClaimants.Find(Token, MaxAllowed);
		
		if (MaxAllowed < NumWantedTokens)
			return false;

		if (!TokenSemaphore.Contains(Token))
			return true; // No entry, so no claimants yet

		const FGentlemanSemaphore& Semaphore = TokenSemaphore[Token]; 
		int nOtherClaimed = 0;
		for (int i = 0; i < Semaphore.Claims.Num(); i++)
		{
			if (Semaphore.Claims[i].Claimant != Claimant)
				nOtherClaimed += Semaphore.Claims[i].NumTokens;
		}

		if (nOtherClaimed + NumWantedTokens <= MaxAllowed)
		{
			// Enough unclaimed tokens left, can claim
			return true;
		}

		// Token is claimed by too many others
		return false;
    }

    // Let us know given object no longer wants to claim token, making it available for others
    void ReleaseToken(const FName& Token, const UObject Claimant, float Cooldown = 0.0)
    {	
		if (!TokenSemaphore.Contains(Token))
			return;

		int NumReleased = 0;
		FGentlemanSemaphore& Semaphore = TokenSemaphore[Token];
		for (int i = Semaphore.Claims.Num() - 1; i >= 0; i--)
		{
			if (Semaphore.Claims[i].Claimant == Claimant)
			{
				NumReleased  = Semaphore.Claims[i].NumTokens;
				Semaphore.Claims.RemoveAtSwap(i);
				TEMPORAL_LOG(this)
					.Event("Released token " + Token + " (" + NumReleased + ") by " + (Claimant == nullptr ? n"null" : Claimant.Name));
				break; // Only one claim per claimant
			}
		}
		
		if ((Cooldown > 0.0) && (NumReleased > 0))
		{
			// Have a cooldown object claim this token
			UGentlemanCooldown Cooldowner;
			if (AvailableCooldowns.Num() > 0)
			{
				Cooldowner = AvailableCooldowns.Last();
				AvailableCooldowns.RemoveAt(AvailableCooldowns.Num() - 1);
			}
			else
			{
				Cooldowner = NewObject(Owner, UGentlemanCooldown, bTransient = true);
			}
			ClaimToken(Token, Cooldowner, NumReleased);
			Cooldowner.CooldownTime  = Time::GameTimeSeconds + Cooldown;
			ActiveCooldowns.Add(Cooldowner);
			SetComponentTickEnabled(true);
		}
    }

	bool IsValidTarget() const
	{
		return TargetInvalidators.Num() == 0;
	}

	void SetInvalidTarget(FInstigator Instigator)
	{
		TargetInvalidators.AddUnique(Instigator);
	}

	void ClearInvalidTarget(FInstigator Instigator)
	{
		TargetInvalidators.Remove(Instigator);
	}

	void DebugDraw()
	{
		bool bDebug = false;
#if EDITOR
		bHazeEditorOnlyDebugBool = true;
		bDebug = bHazeEditorOnlyDebugBool;
#endif
		if (!bDebug)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		PrintToScreen("-----------------------------------------", Color = FLinearColor::Red);
		for(auto IterOpponent : Opponents)
			PrintToScreen("    Opponent: " + IterOpponent.GetName(), 0.0, FLinearColor::Teal);
		PrintToScreen("Num Opponents: " + Opponents.Num(), 0.0, FLinearColor::Teal);
		for(auto AS : TokenSemaphore)
		{
			for(auto IterClaimant : AS.GetValue().Claims)
				PrintToScreen("    Claimant: " + IterClaimant.Claimant.GetName() + " NumTokens: " + IterClaimant.NumTokens, 0.0, FLinearColor::White);
			PrintToScreen("TokenSemaphore: " + AS.GetKey() + " | " + "Num Claimants: " + AS.GetValue().Claims.Num(), 0.0, FLinearColor::White);
		}
		PrintToScreen("Owner: " + Owner.GetName(), 0.0, FLinearColor::Yellow);
	}

}






